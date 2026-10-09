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
      tagline: "Uyghur Latin Yëziqi keyboard for iPhone — offline.",
      navHome: "Home",
      navPrivacy: "Privacy",
      navSupport: "Support",
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
      contactBody: "Email: CONTACT_EMAIL (include iOS version and a short description).",
      privacyTitle: "Privacy Policy",
      privacyUpdated: "Last updated: October 9, 2026",
      privacyNote:
        "Before App Store submit: replace CONTACT_EMAIL below with your real address (search in this file).",
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
    },
    zh: {
      langName: "中文",
      dir: "ltr",
      htmlLang: "zh-Hans",
      brand: "ULY 维吾尔语拉丁键盘",
      tagline: "iPhone 维吾尔语拉丁字母（ULY）键盘 — 离线使用。",
      navHome: "首页",
      navPrivacy: "隐私",
      navSupport: "支持",
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
      contactBody: "邮箱：CONTACT_EMAIL（请注明 iOS 版本与简要说明）。",
      privacyTitle: "隐私政策",
      privacyUpdated: "最近更新：2026 年 10 月 9 日",
      privacyNote: "上架前请将下方 CONTACT_EMAIL 替换为真实邮箱（在本文件中搜索）。",
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
    },
    ug: {
      langName: "ئۇيغۇرچە",
      dir: "rtl",
      htmlLang: "ug",
      brand: "ULY كۇنۇپكا",
      tagline: "iPhone ئۈچۈن ئۇيغۇر لاتىن يېزىقى (ULY) كۇنۇپكىسى — تورسىز.",
      navHome: "باش بەت",
      navPrivacy: "شەخسىيەت",
      navSupport: "قوللاش",
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
      contactBody: "ئېلخەت: CONTACT_EMAIL (iOS نەشرى ۋە قىسقىچە چۈشەندۈرۈشنى قوشۇڭ).",
      privacyTitle: "شەخسىيەت سىياسىتى",
      privacyUpdated: "ئاخىرقى يېڭىلاش: 2026-يىل 10-ئاينىڭ 9-كۈنى",
      privacyNote: "App Store غا يوللاشتىن بۇرۇن تۆۋەندىكى CONTACT_EMAIL نى ھەقىقىي ئادرېسقا ئالماشتۇرۇڭ.",
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
    },
    uly: {
      langName: "Uyghurche",
      dir: "ltr",
      htmlLang: "ug-Latn",
      brand: "ULY Künupka",
      tagline: "iPhone üchün Uyghur Latin Yëziqi (ULY) künupkisi — torsiz.",
      navHome: "Bash bet",
      navPrivacy: "Shexsiyet",
      navSupport: "Qollash",
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
      contactBody: "Élxet: CONTACT_EMAIL (iOS neshri we qisqiche chüshendürüshni qoshung).",
      privacyTitle: "Shexsiyet siyasiti",
      privacyUpdated: "Axirqi yéngilash: 2026-yil 10-ayning 9-küni",
      privacyNote: "App Store gha yollashtin burun töwendiki CONTACT_EMAIL ni heqiqiy adresqa almashturung.",
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
