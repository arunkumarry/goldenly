import { application } from "controllers/application"
import OnboardingController from "controllers/onboarding_controller"
import ProfileSwitcherController from "controllers/profile_switcher_controller"
import InvitationController from "controllers/invitation_controller"
import AddressAutocompleteController from "controllers/address_autocomplete_controller"
import IdentifierController from "controllers/identifier_controller"
import PhoneInputController from "controllers/phone_input_controller"
import RevealController from "controllers/reveal_controller"

application.register("onboarding", OnboardingController)
application.register("profile-switcher", ProfileSwitcherController)
application.register("invitation", InvitationController)
application.register("address-autocomplete", AddressAutocompleteController)
application.register("identifier", IdentifierController)
application.register("phone-input", PhoneInputController)
application.register("reveal", RevealController)
