# Mamba Fast Tracker

App de jejum intermitente + registro de calorias, desenvolvido em Flutter para o
desafio técnico da Mamba Growth (Mobile Apps Division).

> ⚠️ **Nota sobre esta entrega**: este código foi escrito em um ambiente sem
> Flutter SDK/Android SDK instalados, então os arquivos `android/`, `ios/` e o
> `.apk` final **não puderam ser gerados aqui**. O passo a passo abaixo mostra
> exatamente como gerar esses artefatos localmente em poucos minutos.

## Como rodar o projeto

1. Tenha o Flutter instalado (`flutter --version`, recomendado 3.22+).
2. Gere a estrutura de plataformas (android/ios) dentro da pasta do projeto:
   ```bash
   flutter create --org com.mambagrowth --project-name mamba_fast_tracker .
   ```
   Isso vai criar `android/`, `ios/`, etc. **sem sobrescrever** a pasta `lib/`
   já entregue (o Flutter só recria o que falta).
3. Instale as dependências:
   ```bash
   flutter pub get
   ```
4. Ajuste o `android/app/src/main/AndroidManifest.xml` (veja seção abaixo).
5. Rode em um device/emulador:
   ```bash
   flutter run
   ```
6. Gere o build de distribuição:
   ```bash
   flutter build apk --release
   # ou
   flutter build appbundle --release
   ```
   O APK fica em `build/app/outputs/flutter-apk/app-release.apk`.

### Ajustes necessários no AndroidManifest.xml

Dentro de `<manifest>`, adicionar as permissões:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```
E dentro de `<application>`, os receivers do `flutter_local_notifications`
(necessários para a notificação de término sobreviver a reinício do device):
```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
    </intent-filter>
</receiver>
```

## Stack escolhida

- **Flutter** (conforme stack permitida no desafio).
- **Provider** para gerenciamento de estado — escolhido por ser leve, oficial-adjacent
  (mantido pela equipe Flutter), com curva de aprendizado baixa e suficiente
  para o escopo do MVP, sem a complexidade de setup de Bloc/Redux.
- **Hive** para persistência local — NoSQL embarcado, mais rápido que SQLite
  para o tipo de dado aqui (documentos pequenos, sem relações complexas) e
  sem overhead de escrever SQL.
- **flutter_local_notifications** + **timezone** para notificações locais
  agendadas com precisão (início e término do jejum).
- **workmanager** como reforço opcional de background (ver Decisões Técnicas).
- **fl_chart** para o gráfico semanal de calorias.
- **shared_preferences** apenas para guardar o id do usuário logado (sessão).
- **crypto** para hash SHA-256 da senha (nunca armazenamos senha em texto puro).

## Arquitetura utilizada

Arquitetura em camadas inspirada em Clean Architecture, simplificada para o
escopo do desafio (MVVM na prática, com Provider como "ViewModel"):

```
lib/
  core/                 -> constantes, utilitários puros (sem dependência de Flutter widgets específicos)
  data/
    models/             -> entidades serializáveis (Map <-> objeto), sem lógica de UI
    repositories/        -> acesso a dados (Hive) — única camada que sabe que "Hive" existe
    local/               -> configuração das boxes do Hive
  services/             -> integrações com o SO (notificações, background)
  presentation/
    providers/           -> estado da aplicação (ChangeNotifier) + regras de negócio de tela
    screens/              -> telas (Widgets), só leem/chamam os providers
    widgets/              -> componentes reutilizáveis
```

Regra seguida: **screens nunca falam diretamente com repositories** — sempre
passam por um provider. Isso mantém a lógica de negócio testável e
independente de widgets.

### O timer de jejum (core feature) — como garantimos que ele "não quebra"

O requisito mais crítico do desafio é o timer sobreviver a fechar o app,
matar o processo, ou reiniciar o celular. A decisão de design central foi:

> **Nunca contar tempo em uma variável. Sempre guardar timestamps absolutos
> (`startedAt`, `pausedAt`, `accumulatedPause`, `endedAt`) e recalcular
> `elapsed`/`remaining` sob demanda a partir do relógio do sistema.**

Isso significa que:
- Fechar o app não perde nada, porque nada "estava rodando" — o estado é
  100% derivado de dados persistidos no Hive.
- Reabrir o app (`AppLifecycleState.resumed`) simplesmente recalcula com base
  no timestamp salvo, cobrindo qualquer tempo em que o app ficou fechado.
- Pausar/retomar é implementado sem "congelar" nada: apenas acumulamos
  quanto tempo ficou pausado (`accumulatedPause`) e descontamos isso do
  cálculo de tempo decorrido.
- O `Timer.periodic` de 1s que existe no `FastingProvider` é **cosmético**
  (só para a UI atualizar a cada segundo) — ele não é a fonte de verdade do
  tempo, só dispara um recálculo a partir do relógio real.

## Decisões técnicas e trade-offs

- **Notificações vs. serviço de background full-time**: em vez de manter um
  serviço rodando continuamente em background (mais complexo, mais consumo
  de bateria, mais fricção com políticas do Android 12+), a notificação de
  término é **agendada uma única vez** (`zonedSchedule`) para o horário exato
  em que a meta será atingida. O SO cuida de disparar isso mesmo com o app
  fechado. O `workmanager` entra apenas como reforço periódico (a cada 15min)
  para reagendar caso algum fabricante agressivo em economia de bateria mate
  o alarme — implementado de forma enxuta (callback isolado) para não acoplar
  inicialização pesada do Hive dentro do isolate de background.
- **Hive sem `build_runner`/`TypeAdapter` gerado**: optei por serializar os
  modelos manualmente como `Map<String, dynamic>` em vez de gerar adapters
  com codegen. Trade-off: perde um pouco de performance de serialização e
  type-safety em runtime, mas ganha um projeto que compila sem depender de
  rodar `build_runner` antes — reduz fricção de setup para quem for avaliar.
  Com mais tempo, migraria para adapters gerados (mais robusto em produção).
- **Auth local em vez de Firebase Auth**: o desafio aceita as duas opções.
  Optei por local (hash SHA-256 + Hive) para manter o projeto 100% offline e
  sem exigir configuração de projeto Firebase por parte de quem for rodar o
  código (menos fricção de avaliação).
- **Multi-usuário via boxes por `userId`**: cada usuário tem suas próprias
  boxes do Hive (`fasting_sessions_<userId>`, `meals_<userId>`, etc.), então
  os dados de diferentes contas nunca se misturam no mesmo device.
- **Um único jejum ativo por vez**: reflete o uso real do app (não faz
  sentido dois jejuns simultâneos); a tentativa de iniciar um segundo lança
  exceção tratada na UI.

## Bibliotecas utilizadas

Ver `pubspec.yaml`. Resumo: `provider`, `hive`/`hive_flutter`, `crypto`,
`flutter_local_notifications`, `timezone`, `workmanager`, `fl_chart`, `intl`,
`uuid`, `shared_preferences`.

## O que melhoraria com mais tempo

- Testes unitários para `FastingSessionModel.elapsed/remaining` (a lógica
  mais crítica do app) e para os repositories com Hive mockado.
- Migrar Hive para adapters gerados via `build_runner` (mais performático).
- Modo offline-first mais explícito com fila de sincronização, caso o app
  evolua para ter um backend.
- Dark mode com toggle manual (hoje segue `ThemeMode.system`).
- Feature flags (ex.: via `shared_preferences` ou remote config) para
  habilitar features experimentais gradualmente.
- CI simples (GitHub Actions) rodando `flutter analyze` + `flutter test` a
  cada push.
- Tela de edição/exclusão de protocolos customizados (hoje só cria).
- Melhor tratamento de erro de rede/permissão negada de notificação (hoje é
  silencioso caso o usuário negue a permissão).
- Publicação em Play Store (internal test track).

## Tempo gasto no desafio

Aproximadamente 4 a 5 horas de desenvolvimento focado (arquitetura, timer,
notificações, persistência, telas, gráfico e documentação).

## Estrutura de pastas final esperada (após `flutter create .`)

```
mamba_fast_tracker/
  android/          <- gerado por `flutter create`
  ios/              <- gerado por `flutter create`
  lib/              <- entregue neste pacote
  pubspec.yaml      <- entregue neste pacote
  README.md         <- este arquivo
```
