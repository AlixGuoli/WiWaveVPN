import Foundation

/// 文案入口：键在 `locale/*.lproj/Localizable.strings`；必须通过 **`AppLanguageStore`** 解析以支持应用内切换语言。
enum L10n {

    enum Tab {
        static func connect(_ app: AppLanguageStore) -> String { app.tr("tab.connect") }
        static func panel(_ app: AppLanguageStore) -> String { app.tr("tab.panel") }
        static func settings(_ app: AppLanguageStore) -> String { app.tr("tab.settings") }
    }

    enum Chrome {
        static func panel(_ app: AppLanguageStore) -> String { app.tr("chrome.panel") }
        static func help(_ app: AppLanguageStore) -> String { app.tr("chrome.help") }
        static func settings(_ app: AppLanguageStore) -> String { app.tr("chrome.settings") }
    }

    enum Launch {
        static func tagline(_ app: AppLanguageStore) -> String { app.tr("launch.tagline") }
    }

    enum Connect {
        static func nodesA11y(_ app: AppLanguageStore) -> String { app.tr("connect.nodes.a11y") }
        static func currentLine(_ app: AppLanguageStore) -> String { app.tr("connect.current_line") }
        static func heroConnect(_ app: AppLanguageStore) -> String { app.tr("connect.hero.connect") }
        static func heroDisconnect(_ app: AppLanguageStore) -> String { app.tr("connect.hero.disconnect") }
        static func heroBusy(_ app: AppLanguageStore) -> String { app.tr("connect.hero.busy") }
        static func statusOffline(_ app: AppLanguageStore) -> String { app.tr("connect.status.offline") }
        static func statusBusy(_ app: AppLanguageStore) -> String { app.tr("connect.status.busy") }
        static func statusOnline(_ app: AppLanguageStore) -> String { app.tr("connect.status.online") }
        static func statusError(_ app: AppLanguageStore) -> String { app.tr("connect.status.error") }
        static func alertDisconnectTitle(_ app: AppLanguageStore) -> String { app.tr("connect.alert.disconnect.title") }
        static func alertDisconnectConfirm(_ app: AppLanguageStore) -> String { app.tr("connect.alert.disconnect.confirm") }
        static func alertDisconnectCancel(_ app: AppLanguageStore) -> String { app.tr("connect.alert.disconnect.cancel") }
        static func alertDisconnectMessage(_ app: AppLanguageStore) -> String { app.tr("connect.alert.disconnect.message") }
        static func alertRoutesLockedTitle(_ app: AppLanguageStore) -> String { app.tr("connect.alert.routes_locked.title") }
        static func alertRoutesLockedMessage(_ app: AppLanguageStore) -> String { app.tr("connect.alert.routes_locked.message") }
        static func alertRoutesLockedOK(_ app: AppLanguageStore) -> String { app.tr("connect.alert.routes_locked.ok") }
        static func alertNoNetworkTitle(_ app: AppLanguageStore) -> String { app.tr("connect.alert.no_network.title") }
        static func alertNoNetworkMessage(_ app: AppLanguageStore) -> String { app.tr("connect.alert.no_network.message") }
        static func alertNoNetworkOK(_ app: AppLanguageStore) -> String { app.tr("connect.alert.no_network.ok") }
        static func homeTagline(_ app: AppLanguageStore) -> String { app.tr("connect.home.tagline") }
        static func homeChangeRoute(_ app: AppLanguageStore) -> String { app.tr("connect.home.change_route") }
        static func homeOverline(_ app: AppLanguageStore) -> String { app.tr("connect.home.overline") }
        static func homeConsoleLabel(_ app: AppLanguageStore) -> String { app.tr("connect.home.console_label") }
        static func homeSpecLine(_ app: AppLanguageStore) -> String { app.tr("connect.home.spec_line") }
        static func homeRouteCaption(_ app: AppLanguageStore) -> String { app.tr("connect.home.route_caption") }
        static func homeRouteFoot(_ app: AppLanguageStore) -> String { app.tr("connect.home.route_foot") }
        static func homeModeAuto(_ app: AppLanguageStore) -> String { app.tr("connect.home.mode.auto") }
        static func homeModeManual(_ app: AppLanguageStore) -> String { app.tr("connect.home.mode.manual") }
        static func homeBadgeOffline(_ app: AppLanguageStore) -> String { app.tr("connect.home.badge.offline") }
        static func homeBadgeBusy(_ app: AppLanguageStore) -> String { app.tr("connect.home.badge.busy") }
        static func homeBadgeOnline(_ app: AppLanguageStore) -> String { app.tr("connect.home.badge.online") }
        static func homeBadgeError(_ app: AppLanguageStore) -> String { app.tr("connect.home.badge.error") }
        static func homeScribble(_ app: AppLanguageStore) -> String { app.tr("connect.home.scribble") }
        static func homeScopeLabel(_ app: AppLanguageStore) -> String { app.tr("connect.home.scope_label") }
        static func homeTelemetryUp(_ app: AppLanguageStore) -> String { app.tr("connect.home.telemetry.up") }
        static func homeTelemetryDown(_ app: AppLanguageStore) -> String { app.tr("connect.home.telemetry.down") }
        static func homeTelemetryUnit(_ app: AppLanguageStore) -> String { app.tr("connect.home.telemetry.unit") }
        static func homeTelemetrySimulated(_ app: AppLanguageStore) -> String { app.tr("connect.home.telemetry.simulated") }
    }

    enum Nodes {
        static func navTitle(_ app: AppLanguageStore) -> String { app.tr("nodes.nav.title") }
        static func sectionRoutes(_ app: AppLanguageStore) -> String { app.tr("nodes.section.routes") }
        static func footerNote(_ app: AppLanguageStore) -> String { app.tr("nodes.footer.note") }
        static func closeListA11y(_ app: AppLanguageStore) -> String { app.tr("nodes.close.a11y") }
        static func autoBadge(_ app: AppLanguageStore) -> String { app.tr("nodes.auto.badge") }
        static func autoName(_ app: AppLanguageStore) -> String { app.tr("region.auto.name") }
        static func autoSubtitle(_ app: AppLanguageStore) -> String { app.tr("region.auto.subtitle") }
        static func germany(_ app: AppLanguageStore) -> String { app.tr("region.germany") }
        static func netherlands(_ app: AppLanguageStore) -> String { app.tr("region.netherlands") }
        static func uk(_ app: AppLanguageStore) -> String { app.tr("region.uk") }
        static func finland(_ app: AppLanguageStore) -> String { app.tr("region.finland") }
        static func france(_ app: AppLanguageStore) -> String { app.tr("region.france") }
        static func japan(_ app: AppLanguageStore) -> String { app.tr("region.japan") }
        static func singapore(_ app: AppLanguageStore) -> String { app.tr("region.singapore") }
        static func usa(_ app: AppLanguageStore) -> String { app.tr("region.usa") }
        static func canada(_ app: AppLanguageStore) -> String { app.tr("region.canada") }
        static func australia(_ app: AppLanguageStore) -> String { app.tr("region.australia") }
    }

    enum Flow {
        static func progressTitle(_ app: AppLanguageStore) -> String { app.tr("flow.progress.title") }
        static func progressSubtitle(_ app: AppLanguageStore) -> String { app.tr("flow.progress.subtitle") }
        static func progressSection(_ app: AppLanguageStore) -> String { app.tr("flow.progress.section") }
        static func progressSteps(_ app: AppLanguageStore) -> String { app.tr("flow.progress.steps") }
        static func outcomeOk(_ app: AppLanguageStore) -> String { app.tr("flow.outcome.linked_ok") }
        static func outcomeFail(_ app: AppLanguageStore) -> String { app.tr("flow.outcome.linked_fail") }
        static func outcomeUnplugged(_ app: AppLanguageStore) -> String { app.tr("flow.outcome.unplugged") }
        static func dismiss(_ app: AppLanguageStore) -> String { app.tr("flow.outcome.dismiss") }
        static func outcomeSection(_ app: AppLanguageStore) -> String { app.tr("flow.outcome.section") }
        static func outcomeCodeOk(_ app: AppLanguageStore) -> String { app.tr("flow.outcome.code.ok") }
        static func outcomeCodeFail(_ app: AppLanguageStore) -> String { app.tr("flow.outcome.code.fail") }
        static func outcomeCodeUnplug(_ app: AppLanguageStore) -> String { app.tr("flow.outcome.code.unplug") }
        static func outcomeDetailExit(_ app: AppLanguageStore) -> String { app.tr("flow.outcome.detail.exit") }
        static func outcomeDetailTime(_ app: AppLanguageStore) -> String { app.tr("flow.outcome.detail.time") }
        static func outcomeDetailMode(_ app: AppLanguageStore) -> String { app.tr("flow.outcome.detail.mode") }
        static func outcomeSummaryOk(_ app: AppLanguageStore) -> String { app.tr("flow.outcome.summary.ok") }
        static func outcomeSummaryFail(_ app: AppLanguageStore) -> String { app.tr("flow.outcome.summary.fail") }
        static func outcomeSummaryUnplug(_ app: AppLanguageStore) -> String { app.tr("flow.outcome.summary.unplug") }
    }

    enum Dashboard {
        static func sessionOffline(_ app: AppLanguageStore) -> String { app.tr("dashboard.card.session.detail.offline") }
        static func sessionBusy(_ app: AppLanguageStore) -> String { app.tr("dashboard.card.session.detail.busy") }
        static func sessionOnline(_ app: AppLanguageStore) -> String { app.tr("dashboard.card.session.detail.online") }
        static func sessionError(_ app: AppLanguageStore) -> String { app.tr("dashboard.card.session.detail.error") }

        static func stripSessionTitle(_ app: AppLanguageStore) -> String { app.tr("dashboard.strip.session_title") }
        static func stripDurationCaption(_ app: AppLanguageStore) -> String { app.tr("dashboard.strip.duration_caption") }
        static func stripDurationIdle(_ app: AppLanguageStore) -> String { app.tr("dashboard.strip.duration_idle") }
        static func routeDigestTitle(_ app: AppLanguageStore) -> String { app.tr("dashboard.route.digest.title") }
        static func routeLatencyLabel(_ app: AppLanguageStore) -> String { app.tr("dashboard.route.latency.label") }
        static func routeLatencyValue(_ app: AppLanguageStore, _ ms: Int) -> String {
            String(format: app.tr("dashboard.route.latency.value"), locale: app.localeForSwiftUI, ms)
        }
        static func routeGradeLabel(_ app: AppLanguageStore) -> String { app.tr("dashboard.route.grade.label") }
        static func sparkTitle(_ app: AppLanguageStore) -> String { app.tr("dashboard.spark.title") }
        static func checkTitle(_ app: AppLanguageStore) -> String { app.tr("dashboard.check.title") }
        static func checkButton(_ app: AppLanguageStore) -> String { app.tr("dashboard.check.button") }
        static func checkRunning(_ app: AppLanguageStore) -> String { app.tr("dashboard.check.running") }
        static func checkDone(_ app: AppLanguageStore) -> String { app.tr("dashboard.check.done") }
        static func securityTitle(_ app: AppLanguageStore) -> String { app.tr("dashboard.security.title") }
        static func securityItem1(_ app: AppLanguageStore) -> String { app.tr("dashboard.security.item1") }
        static func securityItem2(_ app: AppLanguageStore) -> String { app.tr("dashboard.security.item2") }
        static func securityItem3(_ app: AppLanguageStore) -> String { app.tr("dashboard.security.item3") }
        static func securityItem4(_ app: AppLanguageStore) -> String { app.tr("dashboard.security.item4") }
        static func tipsSectionTitle(_ app: AppLanguageStore) -> String { app.tr("dashboard.tips.section_title") }
        static func tip1Title(_ app: AppLanguageStore) -> String { app.tr("dashboard.tip.1.title") }
        static func tip1Body(_ app: AppLanguageStore) -> String { app.tr("dashboard.tip.1.body") }
        static func tip2Title(_ app: AppLanguageStore) -> String { app.tr("dashboard.tip.2.title") }
        static func tip2Body(_ app: AppLanguageStore) -> String { app.tr("dashboard.tip.2.body") }
        static func tip3Title(_ app: AppLanguageStore) -> String { app.tr("dashboard.tip.3.title") }
        static func tip3Body(_ app: AppLanguageStore) -> String { app.tr("dashboard.tip.3.body") }
        static func tip4Title(_ app: AppLanguageStore) -> String { app.tr("dashboard.tip.4.title") }
        static func tip4Body(_ app: AppLanguageStore) -> String { app.tr("dashboard.tip.4.body") }
        static func tip5Title(_ app: AppLanguageStore) -> String { app.tr("dashboard.tip.5.title") }
        static func tip5Body(_ app: AppLanguageStore) -> String { app.tr("dashboard.tip.5.body") }
    }

    enum Help {
        static func docTitle(_ app: AppLanguageStore) -> String { app.tr("help.doc.title") }
        static func closeScreenA11y(_ app: AppLanguageStore) -> String { app.tr("help.close.a11y") }
        static func whyVpnTitle(_ app: AppLanguageStore) -> String { app.tr("help.section.why_vpn.title") }
        static func whyVpnBody(_ app: AppLanguageStore) -> String { app.tr("help.section.why_vpn.body") }
        static func troubleTitle(_ app: AppLanguageStore) -> String { app.tr("help.section.trouble.title") }
        static func troubleBody(_ app: AppLanguageStore) -> String { app.tr("help.section.trouble.body") }
        static func routesTitle(_ app: AppLanguageStore) -> String { app.tr("help.section.routes.title") }
        static func routesBody(_ app: AppLanguageStore) -> String { app.tr("help.section.routes.body") }
        static func contactTitle(_ app: AppLanguageStore) -> String { app.tr("help.section.contact.title") }
        static func contactBody(_ app: AppLanguageStore) -> String { app.tr("help.section.contact.body") }
    }

    enum Settings {
        static func about(_ app: AppLanguageStore) -> String { app.tr("settings.section.about") }
        static func version(_ app: AppLanguageStore) -> String { app.tr("settings.field.version") }
        static func build(_ app: AppLanguageStore) -> String { app.tr("settings.field.build") }
        static func legal(_ app: AppLanguageStore) -> String { app.tr("settings.section.legal") }
        static func privacyLink(_ app: AppLanguageStore) -> String { app.tr("settings.link.privacy") }
        static func termsLink(_ app: AppLanguageStore) -> String { app.tr("settings.link.terms") }
        static func footerPlaceholder(_ app: AppLanguageStore) -> String { app.tr("settings.footer.placeholder") }
        static func helpEntryBlurb(_ app: AppLanguageStore) -> String { app.tr("settings.help.entry.blurb") }
        static func debugUUIDTitle(_ app: AppLanguageStore) -> String { app.tr("settings.debug.uuid.title") }
        static func debugUUIDCopy(_ app: AppLanguageStore) -> String { app.tr("settings.debug.uuid.copy") }
        static func debugUUIDCancel(_ app: AppLanguageStore) -> String { app.tr("settings.debug.uuid.cancel") }
        static func languageSection(_ app: AppLanguageStore) -> String { app.tr("settings.language.section") }
        static func languageSystem(_ app: AppLanguageStore) -> String { app.tr("settings.language.system") }
        static func languageApplying(_ app: AppLanguageStore) -> String { app.tr("settings.language.applying") }
    }

    enum Onboard {
        static func welcomeTitle(_ app: AppLanguageStore) -> String {
            String(format: app.tr("onboard.welcome.title_format"), AppDisplayName.fromBundle)
        }
        static func welcomeBody(_ app: AppLanguageStore) -> String { app.tr("onboard.welcome.body") }
        static func next(_ app: AppLanguageStore) -> String { app.tr("onboard.next") }
        static func expectTitle(_ app: AppLanguageStore) -> String { app.tr("onboard.expect.title") }
        static func expectBody(_ app: AppLanguageStore) -> String { app.tr("onboard.expect.body") }
        static func expectSettingsHint(_ app: AppLanguageStore) -> String { app.tr("onboard.expect.settings_hint") }
        static func valueTitle(_ app: AppLanguageStore) -> String { app.tr("onboard.value.title") }
        static func valueBullet1(_ app: AppLanguageStore) -> String { app.tr("onboard.value.bullet1") }
        static func valueBullet2(_ app: AppLanguageStore) -> String { app.tr("onboard.value.bullet2") }
        static func valueBullet3(_ app: AppLanguageStore) -> String { app.tr("onboard.value.bullet3") }
        static func privacyHeading(_ app: AppLanguageStore) -> String { app.tr("onboard.privacy.heading") }
        static func privacyIntro(_ app: AppLanguageStore) -> String { app.tr("onboard.privacy.intro") }
        static func privacyDeviceTitle(_ app: AppLanguageStore) -> String { app.tr("onboard.privacy.device.title") }
        static func privacyDeviceBody(_ app: AppLanguageStore) -> String { app.tr("onboard.privacy.device.body") }
        static func privacySessionTitle(_ app: AppLanguageStore) -> String { app.tr("onboard.privacy.session.title") }
        static func privacySessionBody(_ app: AppLanguageStore) -> String { app.tr("onboard.privacy.session.body") }
        static func privacyUsageTitle(_ app: AppLanguageStore) -> String { app.tr("onboard.privacy.usage.title") }
        static func privacyUsageBody(_ app: AppLanguageStore) -> String { app.tr("onboard.privacy.usage.body") }
        static func privacyThirdPartyTitle(_ app: AppLanguageStore) -> String { app.tr("onboard.privacy.thirdparty.title") }
        static func privacyThirdPartyBody(_ app: AppLanguageStore) -> String { app.tr("onboard.privacy.thirdparty.body") }
        static func privacyPolicyFooter(_ app: AppLanguageStore) -> String { app.tr("onboard.privacy.policy_footer") }
        static func privacyAgreeToggle(_ app: AppLanguageStore) -> String { app.tr("onboard.privacy.agree_toggle") }
        static func privacyPlaceholderNote(_ app: AppLanguageStore) -> String { app.tr("onboard.privacy.placeholder_note") }
        static func privacyAgreeContinue(_ app: AppLanguageStore) -> String { app.tr("onboard.privacy.agree_continue") }
        static func privacyDeclineQuit(_ app: AppLanguageStore) -> String { app.tr("onboard.privacy.decline_quit") }
    }
}
