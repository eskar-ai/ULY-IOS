/** UI language for marketing site (not typing input). */
(function () {
  const SUPPORTED = ["en", "zh", "ug", "uly"];
  const STORAGE_KEY = "uly_site_lang";

  const dict = {
    en: {
      langName: "English",
      dir: "ltr",
      htmlLang: "en",
      brand: "ULY Künupka",
      tagline: "Uyghur Latin Yëziqi keyboard for iPhone — offline, private, open source.",
      navHome: "Home",
      navPrivacy: "Privacy",
      navSupport: "Support",
      navLearn: "Learn ULY",
      navGitHub: "GitHub",
      trustBadge1: "On-device only",
      trustBadge2: "No Full Access",
      trustBadge3: "No ads or tracking",
      trustBadge4: "Open source",
      trustTitle: "Private by design",
      trustIntro:
        "Keyboards handle your private text. ULY Künupka is built so typing stays on your iPhone.",
      trust1: "Suggestions and spell check run offline on your device.",
      trust2: "Full Access is not requested — your keystrokes are not sent to us.",
      trust3: "No account, no ads, no analytics SDK in the current app.",
      trust4: "Source code is public so anyone can review how the keyboard works.",
      githubTitle: "Open source",
      githubBody: "If you want to see the open-sourced code, visit the GitHub repository.",
      githubCta: "View code on GitHub",
      footerTrust: "MIT-licensed · Offline typing · Contact: mr.askar@icloud.com",
      enableTitle: "Enable the keyboard",
      enable1: "Install from the App Store",
      enable2: "Settings → General → Keyboard → Keyboards → Add New Keyboard…",
      enable3: "Choose ULY Künupka",
      enable4: "Tap the globe key while typing to switch",
      tipsTitle: "Typing tips",
      tip1: "Long-press e / o / u → ë ö ü",
      tip2: "Long-press c / s / z / g / n → ch sh zh gh ng",
      tip3: "Tap ◐ on the suggestion bar for System / Light / Dark theme",
      contactTitle: "Contact",
      contactBody: "Email: mr.askar@icloud.com (include iOS version and a short description).",
      privacyTitle: "Privacy Policy",
      privacyUpdated: "Last updated: October 9, 2026",
      privacySummary: "Summary",
      privacyS1: "Typing, suggestions, and spell check run on your device.",
      privacyS2: "The keyboard does not request Full Access by default.",
      privacyS3: "No account, no ads, no analytics SDK in the current app.",
      privacyNoCollectTitle: "Data we do not collect",
      privacyNoCollect:
        "We do not collect, transmit, or sell keystrokes, message contents, contacts, location, or advertising identifiers.",
      privacyLocalTitle: "On-device storage",
      privacyLocal:
        "Theme preference and words you accept into suggestions may be stored locally in the keyboard sandbox.",
      privacyContactTitle: "Contact",
      supportTitle: "Support",
      back: "← ULY Künupka",
      learnTitle: "Learn ULY",
      learnTagline: "Arabic script ↔ Uyghur Latin (ULY 2008) — chart and a short tutorial.",
      learnNavChart: "Alphabet chart",
      learnNavTutorial: "Tutorial",
      learnNavPractice: "Practice",
      learnIntroTitle: "What is ULY?",
      learnIntroBody:
        "ULY (Uyghur Latin Yëziqi, 2008) writes Uyghur with Latin letters. Each Arabic letter maps to one Latin letter or digraph. This page helps you read both sides and start typing with ULY Künupka.",
      learnChartTitle: "Alphabet chart",
      learnChartHint:
        "Left: Uyghur Arabic. Right: ULY Latin. Vowels may appear with ئ at the start of a syllable.",
      learnColArabic: "Arabic",
      learnColLatin: "ULY",
      learnColExample: "Example",
      learnSpecialTitle: "Digraphs and special letters",
      learnSpecial1: "ch sh zh gh ng are each one sound — two Latin letters, one Arabic letter.",
      learnSpecial2: "ë ö ü (not e o u alone) match ې ۆ ۈ. On the keyboard: long-press e / o / u.",
      learnSpecial3: "Apostrophe ' stands for ئ inside words (e.g. jem'iyet).",
      learnSpecial4: "q / x / gh are not the same as k / h / g — keep them distinct.",
      learnTutorialTitle: "Short tutorial",
      learnStep1Title: "Learn vowels first",
      learnStep1Body:
        "Memorize a e ë i o ö u ü with their Arabic pairs. Most words are built around these eight vowels.",
      learnStep2Title: "Add common consonants",
      learnStep2Body:
        "Practice b p t d s sh l m n y — then digraphs ch gh ng. Read a short word letter by letter.",
      learnStep3Title: "Read Arabic → write Latin",
      learnStep3Body:
        "Cover the Latin side of the chart, look at an Arabic word, and write the ULY form. Check against the examples below.",
      learnStep4Title: "Type on the keyboard",
      learnStep4Body:
        "Enable ULY Künupka, type the Latin form, and use suggestions to confirm spelling. Long-press for ë ö ü and digraphs.",
      learnPracticeTitle: "Practice words",
      learnPracticeHint: "Try converting Arabic → ULY, then type them in the app.",
      learnKeysTitle: "Typing on ULY Künupka",
      learnKeys3: "Tap a suggestion to complete or correct a word.",
      learnKeysSupport: "Keyboard setup & support →",
    },
    zh: {
      langName: "中文",
      dir: "ltr",
      htmlLang: "zh-Hans",
      brand: "ULY 维吾尔语拉丁键盘",
      tagline: "iPhone 维吾尔语拉丁字母（ULY）键盘 — 离线、注重隐私、开源。",
      navHome: "首页",
      navPrivacy: "隐私",
      navSupport: "支持",
      navLearn: "学习对照",
      navGitHub: "GitHub",
      trustBadge1: "仅在设备本地",
      trustBadge2: "不请求完全访问",
      trustBadge3: "无广告与追踪",
      trustBadge4: "开源",
      trustTitle: "隐私优先",
      trustIntro: "键盘会接触您的私密文字。ULY Künupka 的设计让输入留在您的 iPhone 上。",
      trust1: "联想与拼写检查在设备本地离线运行。",
      trust2: "不请求「完全访问」——击键内容不会发送给我们。",
      trust3: "当前版本无账号、无广告、无分析 SDK。",
      trust4: "源码公开，任何人都可以查看键盘如何工作。",
      githubTitle: "开源",
      githubBody: "如果想查看开源代码，请访问我们的 GitHub 仓库。",
      githubCta: "在 GitHub 查看代码",
      footerTrust: "MIT 许可 · 离线输入 · 联系：mr.askar@icloud.com",
      enableTitle: "启用键盘",
      enable1: "从 App Store 安装",
      enable2: "设置 → 通用 → 键盘 → 键盘 → 添加新键盘…",
      enable3: "选择 ULY Künupka",
      enable4: "打字时用 🌐 切换键盘",
      tipsTitle: "输入提示",
      tip1: "长按 e / o / u → ë ö ü",
      tip2: "长按 c / s / z / g / n → ch sh zh gh ng",
      tip3: "在候选栏点 ◐ 切换 跟随系统 / 浅色 / 深色",
      contactTitle: "联系",
      contactBody: "邮箱：mr.askar@icloud.com（请注明 iOS 版本与简要说明）。",
      privacyTitle: "隐私政策",
      privacyUpdated: "最近更新：2026 年 10 月 9 日",
      privacySummary: "摘要",
      privacyS1: "打字、联想与拼写检查均在您的设备上运行。",
      privacyS2: "键盘默认不请求「完全访问」。",
      privacyS3: "当前版本无账号、无广告、无分析 SDK。",
      privacyNoCollectTitle: "我们不收集的数据",
      privacyNoCollect:
        "我们不会收集、传输或出售击键内容、消息正文、通讯录、位置或广告标识符。",
      privacyLocalTitle: "设备本地存储",
      privacyLocal: "主题偏好以及您从候选中采纳的词可能保存在键盘沙盒本地。",
      privacyContactTitle: "联系方式",
      supportTitle: "支持",
      back: "← ULY 维吾尔语拉丁键盘",
      learnTitle: "学习 ULY",
      learnTagline: "维吾尔语阿拉伯文 ↔ 拉丁文（ULY 2008）对照表与入门教程。",
      learnNavChart: "字母对照",
      learnNavTutorial: "教程",
      learnNavPractice: "练习",
      learnIntroTitle: "什么是 ULY？",
      learnIntroBody:
        "ULY（Uyghur Latin Yëziqi，2008）用拉丁字母书写维吾尔语。每个阿拉伯文字母对应一个拉丁字母或双字母组合。本页帮助你对照两边，并用 ULY Künupka 开始输入。",
      learnChartTitle: "字母对照表",
      learnChartHint: "左：维吾尔语阿拉伯文。右：ULY 拉丁文。元音在音节开头常带 ئ。",
      learnColArabic: "阿拉伯文",
      learnColLatin: "ULY",
      learnColExample: "例词",
      learnSpecialTitle: "双字母与特殊字母",
      learnSpecial1: "ch sh zh gh ng 各是一个音——两个拉丁字母对应一个阿拉伯文字母。",
      learnSpecial2: "ë ö ü（不是单独的 e o u）对应 ې ۆ ۈ。键盘上：长按 e / o / u。",
      learnSpecial3: "撇号 ' 表示词中的 ئ（例如 jem'iyet）。",
      learnSpecial4: "q / x / gh 与 k / h / g 不同，请分开记忆。",
      learnTutorialTitle: "入门教程",
      learnStep1Title: "先记元音",
      learnStep1Body: "记住 a e ë i o ö u ü 及其阿拉伯文对照。多数词由这八个元音构成。",
      learnStep2Title: "再加常用辅音",
      learnStep2Body: "练习 b p t d s sh l m n y，再练双字母 ch gh ng。按字母逐个读短词。",
      learnStep3Title: "看阿拉伯文 → 写拉丁文",
      learnStep3Body: "遮住对照表的拉丁文一侧，看阿拉伯文单词并写出 ULY，再对照下方例词检查。",
      learnStep4Title: "用键盘输入",
      learnStep4Body: "启用 ULY Künupka，输入拉丁形式，用候选确认拼写。长按可出 ë ö ü 与双字母。",
      learnPracticeTitle: "练习词",
      learnPracticeHint: "先试着把阿拉伯文转成 ULY，再到 App 里打出来。",
      learnKeysTitle: "在 ULY Künupka 上输入",
      learnKeys3: "点候选可补全或纠正单词。",
      learnKeysSupport: "键盘启用与支持 →",
    },
    ug: {
      langName: "ئۇيغۇرچە",
      dir: "rtl",
      htmlLang: "ug",
      brand: "ULY كۇنۇپكا",
      tagline: "iPhone ئۈچۈن ئۇيغۇر لاتىن يېزىقى (ULY) كۇنۇپكىسى — تورسىز، شەخسىي، ئوچۇق مەنبە.",
      navHome: "باش بەت",
      navPrivacy: "شەخسىيەت",
      navSupport: "قوللاش",
      navLearn: "ئۆگىنىش",
      navGitHub: "GitHub",
      trustBadge1: "پەقەت ئۈسكۈنىدە",
      trustBadge2: "تولۇق زىيارەت يوق",
      trustBadge3: "ئېلان ياكى ئىز قوغلاش يوق",
      trustBadge4: "ئوچۇق مەنبە",
      trustTitle: "لاھىيەلەشتە شەخسىيەت",
      trustIntro: "كۇنۇپكىلار شەخسىي تېكىستىڭىز بىلەن ئىشلەيدۇ. ULY كۇنۇپكا كىرگۈزۈشنى iPhone ئىچىدە ساقلاش ئۈچۈن قۇرۇلغان.",
      trust1: "تەكلىپ ۋە ئىملا تەكشۈرۈش ئۈسكۈنىڭىزدە تورسىز ئىجرا بولىدۇ.",
      trust2: "«تولۇق زىيارەت» تەلەپ قىلىنمايدۇ — كۇنۇپكا بېسىشلىرىڭىز بىزگە يوللانمايدۇ.",
      trust3: "نۆۋەتتىكى نەشرىدە ھېسابات، ئېلان ياكى ئانالىز SDK يوق.",
      trust4: "مەنبە كودى ئاشكارا، ھەرقانداق كىشى كۇنۇپكىنىڭ قانداق ئىشلەيدىغانلىقىنى كۆرەلەيدۇ.",
      githubTitle: "ئوچۇق مەنبە",
      githubBody: "ئوچۇق مەنبە كودىنى كۆرمەكچى بولسىڭىز، GitHub ئامبىرىنى زىيارەت قىلىڭ.",
      githubCta: "GitHub دا كودنى كۆرۈش",
      footerTrust: "MIT ئىجازىتى · تورسىز كىرگۈزۈش · ئالاقە: mr.askar@icloud.com",
      enableTitle: "كۇنۇپكىنى قوزغىتىش",
      enable1: "App Store دىن قاچىلاڭ",
      enable2: "تەڭشەك → ئادەتتىكى → كۇنۇپكا → كۇنۇپكىلار → يېڭى كۇنۇپكا قوشۇش…",
      enable3: "ULY كۇنۇپكا نى تاللاڭ",
      enable4: "كىرگۈزۈۋاتقاندا يەرشارى كۇنۇپكىسى بىلەن ئالماشتۇرۇڭ",
      tipsTitle: "كىرگۈزۈش ئۇسۇلى",
      tip1: "e / o / u نى ئۇزۇن بېسىڭ → ë ö ü",
      tip2: "c / s / z / g / n نى ئۇزۇن بېسىڭ → ch sh zh gh ng",
      tip3: "تەكلىپ بالدىقىدا ◐ بىلەن سىستېما / يورۇق / قاراڭغۇ ئۇسلۇبىنى تاللاڭ",
      contactTitle: "ئالاقە",
      contactBody: "ئېلخەت: mr.askar@icloud.com (iOS نەشرى ۋە قىسقىچە چۈشەندۈرۈشنى قوشۇڭ).",
      privacyTitle: "شەخسىيەت سىياسىتى",
      privacyUpdated: "ئاخىرقى يېڭىلاش: 2026-يىل 10-ئاينىڭ 9-كۈنى",
      privacySummary: "قىسقىچە",
      privacyS1: "كىرگۈزۈش، تەكلىپ ۋە ئىملا تەكشۈرۈش ئۈسكۈنىڭىزدە ئىجرا بولىدۇ.",
      privacyS2: "كۇنۇپكا سۈكۈتتە «تولۇق زىيارەت» تەلەپ قىلمايدۇ.",
      privacyS3: "نۆۋەتتىكى نەشرىدە ھېسابات، ئېلان ياكى ئانالىز SDK يوق.",
      privacyNoCollectTitle: "بىز توپلىمايدىغان سانلىق مەلۇمات",
      privacyNoCollect:
        "بىز كۇنۇپكا بېسىش، ئۇچۇر مەزمۇنى، ئالاقىداش، ئورۇن ياكى ئېلان پەرقلەندۈرگۈچىنى توپلىمايمىز، يوللىمايمىز ياكى ساتمايمىز.",
      privacyLocalTitle: "ئۈسكۈنە ئىچىدە ساقلاش",
      privacyLocal:
        "ئۇسلۇب مايىللىقى ۋە تەكلىپتىن قوبۇل قىلغان سۆزلەر كۇنۇپكا قۇم ساندۇقىدا يەرلىكتە ساقلىنىشى مۇمكىن.",
      privacyContactTitle: "ئالاقە",
      supportTitle: "قوللاش",
      back: "← ULY كۇنۇپكا",
      learnTitle: "ULY نى ئۆگىنىش",
      learnTagline: "ئەرەب يېزىقى ↔ ئۇيغۇر لاتىن (ULY 2008) سېلىشتۇرما جەدۋەل ۋە قىسقا دەرس.",
      learnNavChart: "ھەرپ جەدۋىلى",
      learnNavTutorial: "دەرس",
      learnNavPractice: "مەشىق",
      learnIntroTitle: "ULY دېگەن نېمە؟",
      learnIntroBody:
        "ULY (ئۇيغۇر لاتىن يېزىقى، 2008) ئۇيغۇرچىنى لاتىن ھەرپلىرى بىلەن يازىدۇ. ھەر بىر ئەرەب ھەرىپى بىر لاتىن ھەرىپى ياكى قوش ھەرپكە ماس كېلىدۇ. بۇ بەت ئىككى تەرەپنى ئوقۇشقا ۋە ULY كۇنۇپكا بىلەن كىرگۈزۈشكە ياردەم بېرىدۇ.",
      learnChartTitle: "ھەرپ سېلىشتۇرما جەدۋىلى",
      learnChartHint: "سول: ئۇيغۇر ئەرەب يېزىقى. ئوڭ: ULY لاتىن. سوزۇق تاۋۇشلار بوغۇم بېشىدا ئ بىلەن كۆرۈلۈشى مۇمكىن.",
      learnColArabic: "ئەرەب",
      learnColLatin: "ULY",
      learnColExample: "مىسال",
      learnSpecialTitle: "قوش ھەرپ ۋە ئالاھىدە ھەرپلەر",
      learnSpecial1: "ch sh zh gh ng ھەر بىرى بىر تاۋۇش — ئىككى لاتىن ھەرىپى، بىر ئەرەب ھەرىپى.",
      learnSpecial2: "ë ö ü (پەقەت e o u ئەمەس) ې ۆ ۈ گە ماس كېلىدۇ. كۇنۇپكىدا: e / o / u نى ئۇزۇن بېسىڭ.",
      learnSpecial3: "ئاپوستروف ' سۆز ئىچىدىكى ئ نى بىلدۈرىدۇ (مەسىلەن jem'iyet).",
      learnSpecial4: "q / x / gh بىلەن k / h / g ئوخشاش ئەمەس — ئايرىم ئېسىڭىزدە تۇتۇڭ.",
      learnTutorialTitle: "قىسقا دەرس",
      learnStep1Title: "ئالدى بىلەن سوزۇق تاۋۇشلار",
      learnStep1Body: "a e ë i o ö u ü ۋە ئۇلارنىڭ ئەرەب جۈپلىرىنى ئېسىڭىزدە تۇتۇڭ. كۆپ سۆزلەر بۇ سەككىز سوزۇق تاۋۇش ئەتراپىدا قۇرۇلىدۇ.",
      learnStep2Title: "ئادەتتىكى ئۈزۈك تاۋۇشلارنى قوشۇڭ",
      learnStep2Body: "b p t d s sh l m n y نى مەشىق قىلىڭ — ئاندىن ch gh ng. قىسقا سۆزنى ھەرپ-ھەرپ ئوقۇڭ.",
      learnStep3Title: "ئەرەبنى ئوقۇپ → لاتىن يېزىڭ",
      learnStep3Body: "جەدۋەلنىڭ لاتىن تەرىپىنى يېپىپ، ئەرەب سۆزىنى قارىتىپ ULY نى يېزىڭ. تۆۋەندىكى مىساللار بىلەن تەكشۈرۈڭ.",
      learnStep4Title: "كۇنۇپكىدا كىرگۈزۈڭ",
      learnStep4Body: "ULY كۇنۇپكىنى قوزغىتىپ لاتىن شەكلىنى كىرگۈزۈڭ، تەكلىپ بىلەن ئىملانى جەزملەشتۈرۈڭ. ë ö ü ۋە قوش ھەرپلەر ئۈچۈن ئۇزۇن بېسىڭ.",
      learnPracticeTitle: "مەشىق سۆزلىرى",
      learnPracticeHint: "ئەرەبنى ULY غا ئايلاندۇرۇپ سىناڭ، ئاندىن ئەپتە كىرگۈزۈڭ.",
      learnKeysTitle: "ULY كۇنۇپكىدا كىرگۈزۈش",
      learnKeys3: "تەكلىپنى بېسىپ سۆزنى تولدۇرۇڭ ياكى تۈزىتىڭ.",
      learnKeysSupport: "كۇنۇپكا تەڭشەش ۋە قوللاش →",
    },
    uly: {
      langName: "Uyghurche",
      dir: "ltr",
      htmlLang: "ug-Latn",
      brand: "ULY Künupka",
      tagline: "iPhone üchün Uyghur Latin Yëziqi (ULY) künupkisi — torsiz, shexsiy, ochuq menbe.",
      navHome: "Bash bet",
      navPrivacy: "Shexsiyet",
      navSupport: "Qollash",
      navLearn: "Öginish",
      navGitHub: "GitHub",
      trustBadge1: "Peqet üskünide",
      trustBadge2: "Toluq ziyaret yoq",
      trustBadge3: "Élan yaki iz qoghlash yoq",
      trustBadge4: "Ochuq menbe",
      trustTitle: "Lahiyeleshte shexsiyet",
      trustIntro: "Künupkilar shexsiy tékistingiz bilen ishleydü. ULY Künupka kirgüzüshni iPhone ichide saqlash üchün qurulghan.",
      trust1: "Teklip we imla tekshürüsh üsküningizde torsiz ijra bolidu.",
      trust2: "«Toluq ziyaret» telep qilinmaydu — künupka bésishliringiz bizge yollanmaydu.",
      trust3: "Nöwettiki neshride hésabat, élan yaki analiz SDK yoq.",
      trust4: "Menbe kodi ashkara, herqandaq kishi künupkining qandaq ishleydighanliqini köreleydü.",
      githubTitle: "Ochuq menbe",
      githubBody: "Ochuq menbe kodini körmekchi bolsingiz, GitHub ambirini ziyaret qiling.",
      githubCta: "GitHub da kodni körüsh",
      footerTrust: "MIT ijaziti · Torsiz kirgüzüsh · Alaqe: mr.askar@icloud.com",
      enableTitle: "Künupkini qozghitish",
      enable1: "App Store din qachilang",
      enable2: "Tengshek → Adettiki → Künupka → Künupkilar → Yéngi künupka qoshush…",
      enable3: "ULY Künupka ni tallang",
      enable4: "Kirgüzüwatqanda yershari künupkisi bilen almashturung",
      tipsTitle: "Kirgüzüsh usuli",
      tip1: "e / o / u ni uzun bésing → ë ö ü",
      tip2: "c / s / z / g / n ni uzun bésing → ch sh zh gh ng",
      tip3: "Teklip baldighida ◐ bilen Sistema / Yoruq / Qarangghu uslubini tallang",
      contactTitle: "Alaqe",
      contactBody: "Élxet: mr.askar@icloud.com (iOS neshri we qisqiche chüshendürüshni qoshung).",
      privacyTitle: "Shexsiyet siyasiti",
      privacyUpdated: "Axirqi yéngilash: 2026-yil 10-ayning 9-küni",
      privacySummary: "Qisqiche",
      privacyS1: "Kirgüzüsh, teklip we imla tekshürüsh üsküningizde ijra bolidu.",
      privacyS2: "Künupka sükütte «toluq ziyaret» telep qilmaydu.",
      privacyS3: "Nöwettiki neshride hésabat, élan yaki analiz SDK yoq.",
      privacyNoCollectTitle: "Biz toplimaydighan sanliq melumat",
      privacyNoCollect:
        "Biz künupka bésish, uchur mezmuni, alaqidash, orun yaki élan perqlendürgüchini toplimaymiz, yollimaymiz yaki satmaymiz.",
      privacyLocalTitle: "Üsküne ichide saqlash",
      privacyLocal:
        "Uslub mayillighi we teklipin qobul qilghan sözler künupka qum sanduqida yerlikte saqlinishi mumkin.",
      privacyContactTitle: "Alaqe",
      supportTitle: "Qollash",
      back: "← ULY Künupka",
      learnTitle: "ULY ni öginish",
      learnTagline: "Ereb yëziqi ↔ Uyghur Latin (ULY 2008) sélishturma jedwel we qisqa ders.",
      learnNavChart: "Herp jedwili",
      learnNavTutorial: "Ders",
      learnNavPractice: "Meshq",
      learnIntroTitle: "ULY dégen néme?",
      learnIntroBody:
        "ULY (Uyghur Latin Yëziqi, 2008) Uyghurche ni Latin herpliri bilen yazidu. Her bir Ereb herpi bir Latin herpi yaki qosh herpke mas kélidu. Bu bet ikki terepni oqushqa we ULY Künupka bilen kirgüzüshke yardem béridu.",
      learnChartTitle: "Herp sélishturma jedwili",
      learnChartHint: "Sol: Uyghur Ereb yëziqi. Ong: ULY Latin. Sozuq tawushlar boghum béshida ئ bilen körünüshi mumkin.",
      learnColArabic: "Ereb",
      learnColLatin: "ULY",
      learnColExample: "Misal",
      learnSpecialTitle: "Qosh herp we alahide herpler",
      learnSpecial1: "ch sh zh gh ng her biri bir tawush — ikki Latin herpi, bir Ereb herpi.",
      learnSpecial2: "ë ö ü (peqet e o u emes) ې ۆ ۈ ge mas kélidu. Künupkida: e / o / u ni uzun bésing.",
      learnSpecial3: "Apostrof ' söz ichidiki ئ ni bildüridu (mesilen jem'iyet).",
      learnSpecial4: "q / x / gh bilen k / h / g oxshash emes — ayri ésingizde tutung.",
      learnTutorialTitle: "Qisqa ders",
      learnStep1Title: "Aldi bilen sozuq tawushlar",
      learnStep1Body: "a e ë i o ö u ü we ularning Ereb jüplirini ésingizde tutung. Köp sözler bu sekkiz sozuq tawush etrapida qurulidu.",
      learnStep2Title: "Adettiki üzük tawushlarni qoshung",
      learnStep2Body: "b p t d s sh l m n y ni meshq qiling — andin ch gh ng. Qisqa sözni herp-herp oqung.",
      learnStep3Title: "Erebni oqup → Latin yézing",
      learnStep3Body: "Jedwelning Latin teripini yépip, Ereb sözini qaraytip ULY ni yézing. Töwendiki misallar bilen tekshürüng.",
      learnStep4Title: "Künupkida kirgüzüng",
      learnStep4Body: "ULY Künupkini qozghitip Latin sheklini kirgüzüng, teklip bilen imlani jezmlishtürüng. ë ö ü we qosh herpler üchün uzun bésing.",
      learnPracticeTitle: "Meshq sözliri",
      learnPracticeHint: "Erebni ULY gha aylandurup sinang, andin eptte kirgüzüng.",
      learnKeysTitle: "ULY Künupkida kirgüzüsh",
      learnKeys3: "Teklipni bésip sözni toldurung yaki tüziting.",
      learnKeysSupport: "Künupka tengshesh we qollash →",
    },
  };

  function resolveLang() {
    const params = new URLSearchParams(location.search);
    const fromQuery = params.get("lang");
    if (fromQuery && SUPPORTED.includes(fromQuery)) {
      try {
        localStorage.setItem(STORAGE_KEY, fromQuery);
      } catch (_) {}
      return fromQuery;
    }
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved && SUPPORTED.includes(saved)) return saved;
    } catch (_) {}
    const nav = (navigator.language || "en").toLowerCase();
    if (nav.startsWith("zh")) return "zh";
    if (nav.startsWith("ug")) {
      if (nav.includes("latn") || nav.includes("latin")) return "uly";
      return "ug";
    }
    return "en";
  }

  function apply() {
    const lang = resolveLang();
    const t = dict[lang];
    document.documentElement.lang = t.htmlLang;
    document.documentElement.dir = t.dir;
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.getAttribute("data-i18n");
      if (key && t[key] != null) el.textContent = t[key];
    });
    document.querySelectorAll("[data-i18n-html]").forEach((el) => {
      const key = el.getAttribute("data-i18n-html");
      if (key && t[key] != null) el.innerHTML = t[key];
    });
    document.querySelectorAll("a[data-lang-link]").forEach((a) => {
      const href = a.getAttribute("href") || "";
      const base = href.split("?")[0];
      a.setAttribute("href", base + "?lang=" + lang);
    });
    document.querySelectorAll("[data-lang-switch]").forEach((a) => {
      const code = a.getAttribute("data-lang-switch");
      a.classList.toggle("active", code === lang);
    });
    const titleEl = document.querySelector("title");
    if (titleEl && titleEl.dataset.i18nTitle) {
      const key = titleEl.dataset.i18nTitle;
      if (t[key]) titleEl.textContent = t[key] + " — ULY Künupka";
    }
  }

  window.ULY_I18N = { apply, resolveLang, dict, SUPPORTED };
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", apply);
  } else {
    apply();
  }
})();
