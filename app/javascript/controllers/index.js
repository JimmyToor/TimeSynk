// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from "./application"

import CalendarController from "./calendar_controller"
application.register("calendar", CalendarController)

import DialogController from "./dialog_controller"
application.register("dialog", DialogController)

import FlatpickrController from "./flatpickr_controller"
application.register("flatpickr", FlatpickrController)

import GameSelectionController from "./game_selection_controller"
application.register("game-selection", GameSelectionController)

import HelloController from "./hello_controller"
application.register("hello", HelloController)

import MutuallyExclusiveSelectController from "./mutually_exclusive_select_controller"
application.register("mutually-exclusive-select", MutuallyExclusiveSelectController)

import NavController from "./nav_controller"
application.register("nav", NavController)

import ProposalSelectionController from "./proposal_selection_controller"
application.register("proposal-selection", ProposalSelectionController)

import ReloadOnRestoreController from "./reload_on_restore_controller"
application.register("reload-on-restore", ReloadOnRestoreController)

import TimezoneController from "./timezone_controller"
application.register("timezone", TimezoneController)

import RailsNestedForm from "@stimulus-components/rails-nested-form"
application.register("rails-nested-form", RailsNestedForm)

import RoleRemovalController from "./role_removal_controller"
application.register("role-removal", RoleRemovalController)

import PagyInitializerController from "./pagy_initializer_controller"
application.register("pagy-initializer", PagyInitializerController)

import ScheduleSummaryWatcherController from "./schedule_summary_watcher_controller"
application.register("schedule-summary-watcher", ScheduleSummaryWatcherController)

import ScheduleSelectionController from "./schedule_selection_controller"
application.register("schedule-selection", ScheduleSelectionController)