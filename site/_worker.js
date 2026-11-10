// Redirect the www duplicate host to the apex domain (301).
// A Pages `_redirects` file is ignored on direct-upload deployments and
// `functions/` is not compiled either, so the redirect lives in this
// `_worker.js` (supported on direct uploads). Only the host changes;
// path + query are kept. All other requests fall through to static assets.
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (url.hostname === "www.socialclone.app") {
      url.hostname = "socialclone.app";
      return Response.redirect(url.toString(), 301);
    }
    return env.ASSETS.fetch(request);
  },
};
