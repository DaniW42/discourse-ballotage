# frozen_string_literal: true

# name: discourse-ballotage
# about: Secret black/white-ball ballots (ballotage) for a member group, with participation oversight
# version: 1.0.0
# authors: Daniel Weber
# url: https://github.com/DaniW42/discourse-ballotage
# required_version: 2026.7.0

enabled_site_setting :ballotage_enabled

register_asset "stylesheets/ballotage.scss"

module ::Ballotage
  PLUGIN_NAME = "discourse-ballotage"
end

require_relative "lib/ballotage/engine"

after_initialize do
  require_relative "app/models/ballotage/ballot"
  require_relative "app/models/ballotage/participation"
  require_relative "app/controllers/ballotage/ballots_controller"
  require_relative "lib/ballotage/guardian_extension"

  reloadable_patch { Guardian.prepend(Ballotage::GuardianExtension) }

  Ballotage::Engine.routes.draw do
    get "/" => "ballots#page"
    get "/manage" => "ballots#page"
    get "/current" => "ballots#current"
    post "/vote" => "ballots#vote"
    get "/ballots" => "ballots#index"
    post "/ballots" => "ballots#create"
    post "/ballots/:id/cancel" => "ballots#cancel"
    post "/ballots/:id/finalize" => "ballots#finalize"
  end

  Discourse::Application.routes.append { mount ::Ballotage::Engine, at: "/ballotage" }
end
