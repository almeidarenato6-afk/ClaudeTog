import { Route, Routes } from "react-router-dom";
import { Layout } from "@/components/Layout";
import { RequireStaff } from "@/features/auth/RequireStaff";
import { LoginPage } from "@/features/auth/LoginPage";
import { AudiosPage } from "@/features/audios/AudiosPage";
import { CategoriesPage } from "@/features/categories/CategoriesPage";
import { AnalyticsPage } from "@/features/analytics/AnalyticsPage";
import { NotificationsPage } from "@/features/notifications/NotificationsPage";
import { StorePromotionsPage } from "@/features/store-promotions/StorePromotionsPage";

export function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route
        element={
          <RequireStaff>
            <Layout />
          </RequireStaff>
        }
      >
        <Route path="/" element={<AudiosPage />} />
        <Route path="/categorias" element={<CategoriesPage />} />
        <Route path="/analytics" element={<AnalyticsPage />} />
        <Route path="/notificacoes" element={<NotificationsPage />} />
        <Route path="/promocoes" element={<StorePromotionsPage />} />
      </Route>
    </Routes>
  );
}
