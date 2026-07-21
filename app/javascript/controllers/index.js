import { application } from "controllers/application"
import OnboardingController from "controllers/onboarding_controller"
import ProfileSwitcherController from "controllers/profile_switcher_controller"
import InvitationController from "controllers/invitation_controller"

application.register("onboarding", OnboardingController)
application.register("profile-switcher", ProfileSwitcherController)
application.register("invitation", InvitationController)
