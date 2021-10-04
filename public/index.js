/** @typedef {{load: (Promise<unknown>); flags: (unknown)}} ElmPagesInit */
/** @type ElmPagesInit */
export default {
  load: async function (elmLoaded) {
    const app = await elmLoaded;
    googleAnalytics();
  },
  flags: function () {
    return "You can decode this in Shared.elm using Json.Decode.string!";
  },
};

function googleAnalytics() {
  (function (i, s, o, g, r, a, m) {
    i['GoogleAnalyticsObject'] = r; i[r] = i[r] || function () {
      (i[r].q = i[r].q || []).push(arguments)
    }, i[r].l = 1 * new Date(); a = s.createElement(o),
      m = s.getElementsByTagName(o)[0]; a.async = 1; a.src = g; m.parentNode.insertBefore(a, m)
  })(window, document, 'script', 'https://www.google-analytics.com/analytics.js', 'ga');

  ga('create', 'UA-147049916-2', 'auto');
  ga('send', 'pageview');
};