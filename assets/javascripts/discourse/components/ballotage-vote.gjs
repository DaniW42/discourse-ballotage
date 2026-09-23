import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { eq, or } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import { formatDateTime } from "../lib/ballotage-format";

export default class BallotageVote extends Component {
  @service dialog;
  @service siteSettings;

  // Replaces the loaded ballot after voting. Holds has_voted only — the
  // chosen colour is never kept anywhere on the client.
  @tracked updatedBallot = null;
  @tracked submitting = false;

  get ballot() {
    return this.updatedBallot ?? this.args.data?.ballot;
  }

  get startsAt() {
    return formatDateTime(this.ballot?.starts_at, this.siteSettings.ballotage_timezone);
  }

  get endsAt() {
    return formatDateTime(this.ballot?.ends_at, this.siteSettings.ballotage_timezone);
  }

  get mayVote() {
    return (
      this.args.data?.can_vote &&
      this.ballot?.state === "open" &&
      !this.ballot?.has_voted
    );
  }

  @action
  vote(choice) {
    this.dialog.yesNoConfirm({
      message: i18n(`ballotage.vote.confirm_${choice}`),
      didConfirm: async () => {
        this.submitting = true;
        try {
          const result = await ajax("/ballotage/vote.json", {
            type: "POST",
            data: { ballot_id: this.ballot.id, choice },
          });
          this.updatedBallot = result.ballot;
        } catch (e) {
          popupAjaxError(e);
        } finally {
          this.submitting = false;
        }
      },
    });
  }

  <template>
    <div class="ballotage-page">
      <h2>{{i18n "ballotage.title"}}</h2>

      {{#if @data.loadError}}
        <div class="alert alert-error">{{i18n "ballotage.load_error"}}</div>
      {{else if this.ballot}}
        <div class="ballotage-ballot">
          <h3 class="ballotage-ballot__title">{{this.ballot.title}}</h3>
          <p class="ballotage-ballot__period">
            {{i18n "ballotage.period" start=this.startsAt end=this.endsAt}}
          </p>

          {{#if (eq this.ballot.state "scheduled")}}
            <p class="ballotage-notice">
              {{i18n "ballotage.vote.not_started" start=this.startsAt}}
            </p>
          {{else if this.ballot.has_voted}}
            <p class="ballotage-notice ballotage-notice--done">
              {{i18n "ballotage.vote.done"}}
            </p>
          {{else if this.mayVote}}
            <p>{{i18n "ballotage.vote.instructions"}}</p>
            <div class="ballotage-choices">
              <DButton
                @action={{fn this.vote "black"}}
                @label="ballotage.choice.black"
                @disabled={{this.submitting}}
                class="ballotage-choice ballotage-choice--black"
              />
              <DButton
                @action={{fn this.vote "white"}}
                @label="ballotage.choice.white"
                @disabled={{this.submitting}}
                class="ballotage-choice ballotage-choice--white"
              />
            </div>
          {{else if @data.can_vote}}
            <p class="ballotage-notice">{{i18n "ballotage.vote.closed"}}</p>
          {{else}}
            <p class="ballotage-notice">{{i18n "ballotage.vote.not_eligible"}}</p>
          {{/if}}
        </div>
      {{else if (or @data.can_vote @data.can_oversee)}}
        <p class="ballotage-notice">{{i18n "ballotage.none"}}</p>
      {{else}}
        <p class="ballotage-notice">{{i18n "ballotage.vote.not_eligible"}}</p>
      {{/if}}

      {{#if @data.can_oversee}}
        <p class="ballotage-manage-link">
          <LinkTo @route="ballotage.manage">{{i18n "ballotage.manage.link"}}</LinkTo>
        </p>
      {{/if}}
    </div>
  </template>
}
