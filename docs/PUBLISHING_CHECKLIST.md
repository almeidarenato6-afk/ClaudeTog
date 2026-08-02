# Checklist de publicação nas lojas

## Geral (todas as lojas)
- [ ] Nome definitivo aprovado: **Vai Márcia** (desenvolvedor: **TogPlay**)
- [ ] Ícone final em todas as resoluções exigidas (ver por loja abaixo) — arte oficial da TogPlay pendente, ver `docs/BRANDING.md`
- [ ] Splash screen / launch screen com identidade visual final
- [ ] Política de privacidade publicada em URL pública (`store-assets/privacy/PRIVACY_POLICY.md` como fonte; publicar em `https://www.lojatogplay.com.br/privacidade` ou equivalente)
- [ ] Termos de uso publicados (`store-assets/privacy/TERMS_OF_USE.md`)
- [ ] Textos de descrição curta/longa em pt-BR (e opcionalmente en-US)
- [ ] Screenshots reais de dispositivo (não mockup) para cada form factor
- [ ] Classificação indicativa / content rating preenchida (conteúdo livre — sem violência, sem conteúdo adulto)
- [ ] Conta de desenvolvedor TogPlay criada e verificada em cada loja
- [ ] Certificados/assinatura de release gerados e armazenados com segurança (nunca commitados no repo)

## Google Play (Android)
- [ ] Ícone 512×512, feature graphic 1024×500
- [ ] Screenshots: telefone (mín. 2), 7" e 10" tablet se aplicável
- [ ] App Bundle (`.aab`) assinado com Play App Signing
- [ ] `AndroidManifest.xml` com permissões justificadas (Bluetooth, gravação de áudio, notificações) — declaração de uso de permissões sensíveis no Play Console
- [ ] Formulário de segurança de dados (Data Safety) preenchido, coerente com a política de privacidade
- [ ] Target API level dentro do mínimo exigido pelo Google no momento do envio
- [ ] Teste interno → fechado → aberto → produção (faixas de release)

## Apple App Store (iOS)
- [ ] Ícone 1024×1024 sem transparência
- [ ] Screenshots por tamanho de tela obrigatório (6.7", 6.5", 5.5", conforme exigência vigente)
- [ ] App Privacy (nutrition label) preenchido no App Store Connect
- [ ] `Info.plist` com `NSBluetoothAlwaysUsageDescription`, `NSMicrophoneUsageDescription`, modo de áudio em background declarado
- [ ] Build via Xcode Cloud/Transporter, TestFlight interno → externo antes de produção
- [ ] Revisão de guideline 4.2 (mínima funcionalidade) — garantir que o app demonstra valor imediato sem watch pareado (modo `phoneOnly`)

## Wear OS (Google Play, categoria Wear)
- [ ] App declarado como "Wear OS app" no Play Console (pode ser standalone ou companion)
- [ ] Testado em pelo menos 2 fabricantes (Samsung Galaxy Watch, Pixel Watch)
- [ ] Ícone e screenshots específicos de relógio
- [ ] Validação de que o app funciona standalone quando o celular está fora de alcance (mensagem clara, não crash)

## watchOS (App Store, target watch)
- [ ] Watch App embutido no mesmo app iOS (arquitetura obrigatória da Apple)
- [ ] Complicações (opcional, roadmap futuro) documentadas como não implementadas nesta fase
- [ ] Testado em Apple Watch Series recente e um modelo mais antigo (SE) para validar fallback `RELAY`

## Garmin Connect IQ Store
- [ ] Conta de desenvolvedor Garmin Connect IQ criada
- [ ] `manifest.xml` com lista de dispositivos suportados validada contra dispositivos reais/simulador
- [ ] Ícone launcher (Garmin exige tamanhos específicos por família de dispositivo)
- [ ] Revisão do processo de certificação Garmin (mais manual/lento que Google/Apple — planejar prazo maior)
- [ ] Teste no simulador Connect IQ para todos os dispositivos-alvo declarados no `garmin_capability_table.json`

## Galaxy Store (quando aplicável)
- [ ] Build Android compatível (mesmo `.apk`/`.aab` da Play Store geralmente reaproveitável)
- [ ] Metadados adaptados às exigências do Galaxy Store Seller Portal
- [ ] Considerar exclusividade de features para One UI Watch, se relevante no futuro

## Pós-lançamento
- [ ] Monitoramento de crash (Firebase Crashlytics) configurado antes do primeiro release público
- [ ] Canal de suporte/feedback visível no app (link ou e-mail TogPlay)
- [ ] Plano de resposta a reviews negativos definido
