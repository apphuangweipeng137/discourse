import I18n from "I18n";
import Controller from "@ember/controller";
import { popupAjaxError } from "discourse/lib/ajax-error";
import bootbox from "bootbox";

export default Controller.extend({
  actions: {
    destroy(webhook) {
      return bootbox.confirm(
        I18n.t("admin.web_hooks.delete_confirm"),
        I18n.t("no_value"),
        I18n.t("yes_value"),
        (result) => {
          if (result) {
            webhook
              .destroyRecord()
              .then(() => {
                this.model.removeObject(webhook);
              })
              .catch(popupAjaxError);
          }
        }
      );
    },

    loadMore() {
      this.model.loadMore();
    },
  },
});
