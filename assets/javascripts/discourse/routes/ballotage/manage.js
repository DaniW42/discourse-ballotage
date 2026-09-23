import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class BallotageManageRoute extends DiscourseRoute {
  async model() {
    try {
      return await ajax("/ballotage/ballots.json");
    } catch (e) {
      return { loadError: true, forbidden: e.jqXHR?.status === 403 };
    }
  }

  titleToken() {
    return i18n("ballotage.manage.title");
  }
}
