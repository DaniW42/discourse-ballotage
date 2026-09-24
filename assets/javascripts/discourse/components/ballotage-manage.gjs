import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import { formatDateTime, isoDateFromToday } from "../lib/ballotage-format";

const DEFAULT_START_TIME = "00:01";
const DEFAULT_END_TIME = "23:59";

export default class BallotageManage extends Component {
  @service dialog;
  @service router;
  @service siteSettings;

  @tracked title = "";
  @tracked startDate = isoDateFromToday(1);
  @tracked endDate = isoDateFromToday(7);
  @tracked customTimes = false;
  @tracked startTime = DEFAULT_START_TIME;
  @tracked endTime = DEFAULT_END_TIME;
  @tracked submitting = false;

  get rows() {
    const tz = this.siteSettings.ballotage_timezone;
    return (this.args.data?.ballots ?? []).map((b) => ({
      ...b,
      startsAt: formatDateTime(b.starts_at, tz),
      endsAt: formatDateTime(b.ends_at, tz),
      stateLabel: this.stateLabel(b),
      participation: this.participationLabel(b),
      over: b.state === "ended" || b.state === "cancelled",
    }));
  }

  // Only one ballot at a time: no form while one is scheduled or running.
  get hasActiveBallot() {
    return (this.args.data?.ballots ?? []).some(
      (b) => b.state === "scheduled" || b.state === "open"
    );
  }

  participationLabel(ballot) {
    const total = this.args.data?.eligible_count;
    return total
      ? i18n("ballotage.manage.participation_of", {
          voted: ballot.voter_count,
          total,
        })
      : i18n("ballotage.manage.participation", { voted: ballot.voter_count });
  }

  stateLabel(ballot) {
    if (ballot.finalized) {
      return i18n(
        ballot.state === "cancelled"
          ? "ballotage.state.cancelled"
          : "ballotage.state.completed"
      );
    }
    return i18n(`ballotage.state.${ballot.state}`);
  }

  @action
  updateField(field, event) {
    this[field] = event.target.value;
  }

  @action
  toggleCustomTimes(event) {
    this.customTimes = event.target.checked;
    if (!this.customTimes) {
      this.startTime = DEFAULT_START_TIME;
      this.endTime = DEFAULT_END_TIME;
    }
  }

  @action
  async create(event) {
    event.preventDefault();
    this.submitting = true;
    try {
      await ajax("/ballotage/ballots.json", {
        type: "POST",
        data: {
          title: this.title,
          start_date: this.startDate,
          end_date: this.endDate,
          start_time: this.startTime,
          end_time: this.endTime,
        },
      });
      this.title = "";
      this.router.refresh();
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.submitting = false;
    }
  }

  @action
  cancel(ballot) {
    this.dialog.yesNoConfirm({
      message: i18n("ballotage.manage.confirm_cancel", { title: ballot.title }),
      didConfirm: () =>
        this.post(`/ballotage/ballots/${ballot.id}/cancel.json`),
    });
  }

  @action
  finalize(ballot) {
    this.dialog.deleteConfirm({
      title: i18n("ballotage.manage.finalize_title"),
      message: i18n("ballotage.manage.confirm_finalize", {
        title: ballot.title,
      }),
      confirmButtonLabel: "ballotage.manage.finalize",
      didConfirm: () =>
        this.post(`/ballotage/ballots/${ballot.id}/finalize.json`),
    });
  }

  @action
  deleteBallot(ballot) {
    this.dialog.deleteConfirm({
      title: i18n("ballotage.manage.delete_title"),
      message: i18n("ballotage.manage.confirm_delete", { title: ballot.title }),
      didConfirm: () =>
        this.post(`/ballotage/ballots/${ballot.id}.json`, "DELETE"),
    });
  }

  async post(url, type = "POST") {
    try {
      await ajax(url, { type });
      this.router.refresh();
    } catch (e) {
      popupAjaxError(e);
    }
  }

  <template>
    <div class="ballotage-page ballotage-manage">
      <h2>{{i18n "ballotage.manage.title"}}</h2>
      <p><LinkTo @route="ballotage.index">{{i18n
            "ballotage.manage.back"
          }}</LinkTo></p>

      {{#if @data.forbidden}}
        <div class="alert alert-error">{{i18n
            "ballotage.manage.forbidden"
          }}</div>
      {{else if @data.loadError}}
        <div class="alert alert-error">{{i18n "ballotage.load_error"}}</div>
      {{else}}
        {{#if @data.can_manage}}
          {{#if this.hasActiveBallot}}
            <p class="ballotage-notice">{{i18n
                "ballotage.manage.one_at_a_time"
              }}</p>
          {{else}}
            <form class="ballotage-form" {{on "submit" this.create}}>
              <h3>{{i18n "ballotage.manage.new"}}</h3>
              <label>
                {{i18n "ballotage.manage.form.title"}}
                <input
                  type="text"
                  required
                  maxlength="255"
                  value={{this.title}}
                  placeholder={{i18n "ballotage.manage.form.title_placeholder"}}
                  {{on "input" (fn this.updateField "title")}}
                />
              </label>
              {{! Start and end each keep their day and optional time together,
                  so ticking "custom times" doesn't reflow the whole row. }}
              <div class="ballotage-form__dates">
                <div class="ballotage-form__when">
                  <label class="ballotage-form__date">
                    {{i18n "ballotage.manage.form.start_date"}}
                    <input
                      type="date"
                      required
                      value={{this.startDate}}
                      {{on "input" (fn this.updateField "startDate")}}
                    />
                  </label>
                  {{#if this.customTimes}}
                    <label class="ballotage-form__time">
                      {{i18n "ballotage.manage.form.start_time"}}
                      <input
                        type="time"
                        required
                        value={{this.startTime}}
                        {{on "input" (fn this.updateField "startTime")}}
                      />
                    </label>
                  {{/if}}
                </div>
                <div class="ballotage-form__when">
                  <label class="ballotage-form__date">
                    {{i18n "ballotage.manage.form.end_date"}}
                    <input
                      type="date"
                      required
                      value={{this.endDate}}
                      {{on "input" (fn this.updateField "endDate")}}
                    />
                  </label>
                  {{#if this.customTimes}}
                    <label class="ballotage-form__time">
                      {{i18n "ballotage.manage.form.end_time"}}
                      <input
                        type="time"
                        required
                        value={{this.endTime}}
                        {{on "input" (fn this.updateField "endTime")}}
                      />
                    </label>
                  {{/if}}
                </div>
              </div>
              <label class="ballotage-form__checkbox">
                <input
                  type="checkbox"
                  checked={{this.customTimes}}
                  {{on "change" this.toggleCustomTimes}}
                />
                {{i18n "ballotage.manage.form.custom_times"}}
              </label>
              {{#unless this.customTimes}}
                <p class="ballotage-hint">{{i18n
                    "ballotage.manage.form.default_times_hint"
                  }}</p>
              {{/unless}}
              <button
                type="submit"
                class="btn btn-primary"
                disabled={{this.submitting}}
              >
                {{i18n "ballotage.manage.form.submit"}}
              </button>
            </form>
          {{/if}}
        {{/if}}

        <h3>{{i18n "ballotage.manage.list"}}</h3>
        {{#each this.rows as |row|}}
          <div class="ballotage-card ballotage-card--{{row.state}}">
            <div class="ballotage-card__head">
              <strong>{{row.title}}</strong>
              <span class="ballotage-badge">{{row.stateLabel}}</span>
            </div>
            <p class="ballotage-ballot__period">
              {{i18n "ballotage.period" start=row.startsAt end=row.endsAt}}
            </p>

            {{#unless row.finalized}}
              <p>{{row.participation}}</p>
              {{#if row.voters.length}}
                <details>
                  <summary>{{i18n "ballotage.manage.voters"}}</summary>
                  <ul class="ballotage-voters">
                    {{#each row.voters as |voter|}}
                      <li>{{voter.username}}{{#if voter.name}}
                          ({{voter.name}}){{/if}}</li>
                    {{/each}}
                  </ul>
                </details>
              {{/if}}

              {{#if row.over}}
                <div class="ballotage-result">
                  <span class="ballotage-result__black">
                    {{i18n "ballotage.choice.black"}}:
                    <strong>{{row.black_count}}</strong>
                  </span>
                  <span class="ballotage-result__white">
                    {{i18n "ballotage.choice.white"}}:
                    <strong>{{row.white_count}}</strong>
                  </span>
                </div>
              {{else}}
                <p class="ballotage-hint">{{i18n
                    "ballotage.manage.result_after_end"
                  }}</p>
              {{/if}}
            {{/unless}}

            {{#if @data.can_manage}}
              <div class="ballotage-card__actions">
                {{#if row.cancellable}}
                  <DButton
                    @action={{fn this.cancel row}}
                    @icon="xmark"
                    @label="ballotage.manage.cancel"
                    class="btn-default"
                  />
                {{/if}}
                {{#if row.finalizable}}
                  <DButton
                    @action={{fn this.finalize row}}
                    @icon="lock"
                    @label="ballotage.manage.finalize"
                    class="btn-danger"
                  />
                {{/if}}
                {{#if row.deletable}}
                  <DButton
                    @action={{fn this.deleteBallot row}}
                    @icon="trash-can"
                    @label="ballotage.manage.delete"
                    class="btn-danger"
                  />
                {{/if}}
              </div>
            {{/if}}
          </div>
        {{else}}
          <p class="ballotage-notice">{{i18n "ballotage.manage.empty"}}</p>
        {{/each}}
      {{/if}}
    </div>
  </template>
}
