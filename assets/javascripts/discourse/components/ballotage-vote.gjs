import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { eq, or } from "discourse/truth-helpers";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import {
  elapsedPercent,
  formatDateTime,
  formatRelative,
} from "../lib/ballotage-format";

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
    return formatDateTime(
      this.ballot?.starts_at,
      this.siteSettings.ballotage_timezone
    );
  }

  get endsAt() {
    return formatDateTime(
      this.ballot?.ends_at,
      this.siteSettings.ballotage_timezone
    );
  }

  get stateLabel() {
    return i18n(`ballotage.state.${this.ballot?.state}`);
  }

  get timeHint() {
    if (this.ballot?.state === "scheduled") {
      return i18n("ballotage.vote.starts_relative", {
        relative: formatRelative(this.ballot.starts_at),
      });
    }
    if (this.ballot?.state === "open") {
      return i18n("ballotage.vote.ends_relative", {
        relative: formatRelative(this.ballot.ends_at),
      });
    }
    return null;
  }

  get progressStyle() {
    const pct = elapsedPercent(this.ballot?.starts_at, this.ballot?.ends_at);
    return htmlSafe(`width: ${pct}%`);
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
      <h2 class="ballotage-page__title">{{i18n "ballotage.title"}}</h2>

      {{#if @data.loadError}}
        <div class="alert alert-error">{{i18n "ballotage.load_error"}}</div>
      {{else if this.ballot}}
        <section class="ballotage-panel ballotage-panel--{{this.ballot.state}}">
          <header class="ballotage-panel__header">
            <span class="ballotage-status ballotage-status--{{this.ballot.state}}">
              {{this.stateLabel}}
            </span>
            <h3 class="ballotage-panel__title">{{this.ballot.title}}</h3>
            <p class="ballotage-panel__meta">
              {{dIcon "calendar-days"}}
              <span>{{i18n "ballotage.period" start=this.startsAt end=this.endsAt}}</span>
            </p>
            {{#if this.timeHint}}
              <p class="ballotage-panel__meta">
                {{dIcon "clock"}}
                <span>{{this.timeHint}}</span>
              </p>
            {{/if}}
            {{#if (eq this.ballot.state "open")}}
              <div class="ballotage-progress" aria-hidden="true">
                <span class="ballotage-progress__bar" style={{this.progressStyle}}></span>
              </div>
            {{/if}}
          </header>

          <div class="ballotage-panel__body">
            {{#if (eq this.ballot.state "scheduled")}}
              <p class="ballotage-panel__text">
                {{i18n "ballotage.vote.not_started" start=this.startsAt}}
              </p>
            {{else if this.ballot.has_voted}}
              <div class="ballotage-done">
                <span class="ballotage-done__icon">{{dIcon "check"}}</span>
                <div>
                  <p class="ballotage-done__title">{{i18n "ballotage.vote.done"}}</p>
                  <p class="ballotage-done__text">{{i18n "ballotage.vote.done_hint"}}</p>
                </div>
              </div>
            {{else if this.mayVote}}
              <p class="ballotage-panel__text">{{i18n "ballotage.vote.instructions"}}</p>
              <div class="ballotage-choices">
                <button
                  type="button"
                  class="ballotage-choice ballotage-choice--black"
                  disabled={{this.submitting}}
                  {{on "click" (fn this.vote "black")}}
                >
                  <span class="ballotage-choice__ball" aria-hidden="true"></span>
                  <span class="ballotage-choice__label">{{i18n "ballotage.choice.black"}}</span>
                </button>
                <button
                  type="button"
                  class="ballotage-choice ballotage-choice--white"
                  disabled={{this.submitting}}
                  {{on "click" (fn this.vote "white")}}
                >
                  <span class="ballotage-choice__ball" aria-hidden="true"></span>
                  <span class="ballotage-choice__label">{{i18n "ballotage.choice.white"}}</span>
                </button>
              </div>
            {{else if @data.can_vote}}
              <p class="ballotage-panel__text">{{i18n "ballotage.vote.closed"}}</p>
            {{else}}
              <p class="ballotage-panel__text">{{i18n "ballotage.vote.not_eligible"}}</p>
            {{/if}}
          </div>
        </section>
      {{else}}
        <section class="ballotage-panel ballotage-panel--empty">
          <p class="ballotage-panel__text">
            {{#if (or @data.can_vote @data.can_oversee)}}
              {{i18n "ballotage.none"}}
            {{else}}
              {{i18n "ballotage.vote.not_eligible"}}
            {{/if}}
          </p>
        </section>
      {{/if}}

      {{#if @data.info_text}}
        <aside class="ballotage-info">
          {{dIcon "circle-info"}}
          <p class="ballotage-info__text">{{@data.info_text}}</p>
        </aside>
      {{/if}}

      {{#if @data.can_oversee}}
        <p class="ballotage-manage-link">
          <LinkTo @route="ballotage.manage">{{i18n "ballotage.manage.link"}}</LinkTo>
        </p>
      {{/if}}
    </div>
  </template>
}
