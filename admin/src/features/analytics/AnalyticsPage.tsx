import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Line,
  LineChart,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { listAnalyticsSummary } from "@/lib/api/analytics";
import { PageHeader } from "@/components/PageHeader";
import { Spinner, ErrorState } from "@/components/Spinner";
import { EmptyState } from "@/components/EmptyState";
import { StatCard } from "./StatCard";
import type { AnalyticsSummary } from "@/lib/api/types";

const CHART_COLORS = ["#ff4d14", "#2c3d67", "#ff9d71", "#7d92bf", "#c7240a"];

function toISODate(d: Date) {
  return d.toISOString().slice(0, 10);
}

function useDefaultRange() {
  return useMemo(() => {
    const end = new Date();
    const start = new Date();
    start.setDate(start.getDate() - 29);
    return { rangeStart: toISODate(start), rangeEnd: toISODate(end) };
  }, []);
}

export function AnalyticsPage() {
  const defaultRange = useDefaultRange();
  const [rangeStart, setRangeStart] = useState(defaultRange.rangeStart);
  const [rangeEnd, setRangeEnd] = useState(defaultRange.rangeEnd);

  const summaryQuery = useQuery({
    queryKey: ["analytics-summary", rangeStart, rangeEnd],
    queryFn: () => listAnalyticsSummary({ rangeStart, rangeEnd }),
  });

  return (
    <div>
      <PageHeader
        title="Analytics"
        description="Uso do app, engajamento e distribuição por dispositivo."
      />

      <div className="mb-6 flex flex-wrap items-end gap-3">
        <div>
          <label className="mb-1 block text-xs font-medium text-slate-500">De</label>
          <input
            type="date"
            value={rangeStart}
            max={rangeEnd}
            onChange={(e) => setRangeStart(e.target.value)}
            className="rounded-lg border border-slate-300 px-3 py-2 text-sm"
          />
        </div>
        <div>
          <label className="mb-1 block text-xs font-medium text-slate-500">Até</label>
          <input
            type="date"
            value={rangeEnd}
            min={rangeStart}
            max={toISODate(new Date())}
            onChange={(e) => setRangeEnd(e.target.value)}
            className="rounded-lg border border-slate-300 px-3 py-2 text-sm"
          />
        </div>
      </div>

      {summaryQuery.isLoading && <Spinner label="Carregando analytics…" />}
      {summaryQuery.isError && (
        <ErrorState
          message="Não foi possível carregar o resumo de analytics."
          onRetry={() => summaryQuery.refetch()}
        />
      )}

      {summaryQuery.isSuccess && (
        <AnalyticsContent data={summaryQuery.data} />
      )}
    </div>
  );
}

function AnalyticsContent({ data }: { data: AnalyticsSummary }) {
  const hasTrend = data.dailyTrend.length > 0;

  return (
    <div className="flex flex-col gap-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Total de reproduções" value={data.totalPlays.toLocaleString("pt-BR")} />
        <StatCard label="Usuários no período" value={data.totalUsers.toLocaleString("pt-BR")} />
        <StatCard label="DAU (médio)" value={data.dau.toLocaleString("pt-BR")} />
        <StatCard
          label="Duração média de sessão"
          value={`${Math.round(data.avgSessionSeconds / 60)} min`}
        />
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <ChartCard title="Reproduções e DAU por dia">
          {hasTrend ? (
            <ResponsiveContainer width="100%" height={260}>
              <LineChart data={data.dailyTrend}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis dataKey="date" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Line type="monotone" dataKey="plays" stroke="#ff4d14" strokeWidth={2} dot={false} name="Reproduções" />
                <Line type="monotone" dataKey="dau" stroke="#2c3d67" strokeWidth={2} dot={false} name="DAU" />
              </LineChart>
            </ResponsiveContainer>
          ) : (
            <EmptyState title="Sem dados no período selecionado" />
          )}
        </ChartCard>

        <ChartCard title="Top áudios">
          {data.topAudios.length > 0 ? (
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={data.topAudios} layout="vertical" margin={{ left: 24 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis type="number" tick={{ fontSize: 11 }} />
                <YAxis
                  type="category"
                  dataKey="title"
                  tick={{ fontSize: 11 }}
                  width={140}
                />
                <Tooltip />
                <Bar dataKey="plays" fill="#ff4d14" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <EmptyState title="Nenhum áudio reproduzido no período" />
          )}
        </ChartCard>

        <ChartCard title="Estratégia de reprodução">
          {data.byPlaybackStrategy.length > 0 ? (
            <ResponsiveContainer width="100%" height={260}>
              <PieChart>
                <Pie
                  data={data.byPlaybackStrategy}
                  dataKey="count"
                  nameKey="strategy"
                  outerRadius={90}
                  label
                >
                  {data.byPlaybackStrategy.map((entry, i) => (
                    <Cell key={entry.strategy} fill={CHART_COLORS[i % CHART_COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <EmptyState title="Sem dados de estratégia de reprodução" />
          )}
        </ChartCard>

        <ChartCard title="Modelos de relógio">
          {data.byWatchModel.length > 0 ? (
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={data.byWatchModel}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis dataKey="model" tick={{ fontSize: 11 }} interval={0} angle={-20} textAnchor="end" height={60} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Bar dataKey="count" fill="#2c3d67" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <EmptyState title="Sem dados de dispositivos" />
          )}
        </ChartCard>
      </div>

      <ChartCard title="Modelos de celular">
        {data.byPhoneModel.length > 0 ? (
          <ResponsiveContainer width="100%" height={240}>
            <BarChart data={data.byPhoneModel}>
              <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
              <XAxis dataKey="model" tick={{ fontSize: 11 }} interval={0} angle={-20} textAnchor="end" height={60} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip />
              <Bar dataKey="count" fill="#ff7038" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        ) : (
          <EmptyState title="Sem dados de dispositivos" />
        )}
      </ChartCard>
    </div>
  );
}

function ChartCard({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-4">
      <h3 className="mb-3 text-sm font-semibold text-slate-700">{title}</h3>
      {children}
    </div>
  );
}
