import { useEffect, useRef, useState } from "react";
import { ActivityIndicator, Alert, Image, Keyboard, KeyboardAvoidingView, Linking, Modal, Platform, SafeAreaView, ScrollView, StyleSheet, Switch, Text, TextInput, TouchableOpacity, View } from "react-native";
import { StatusBar } from "expo-status-bar";
import * as Speech from "expo-speech";
import { ExpoSpeechRecognitionModule, useSpeechRecognitionEvent } from "expo-speech-recognition";
import DateTimePicker from "@react-native-community/datetimepicker";
import { clearTokens, getSession, requestCode, saveSession, setActiveCareProfile, signIn, signUp } from "../services/auth";
import { askCareAgent, confirmCareAction } from "../services/careAgent";
import { createServiceRequest, fetchDashboard, registerPushToken, unregisterPushToken } from "../services/careData";
import { getPlace, searchPlaces } from "../services/places";
import { forceSpeakerOutput } from "../modules/goldenly-audio-session/src";
import { cancelLocalCareNotifications, clearStoredPushToken, registerForRemoteNotifications, scheduleLocalCareNotifications, storedPushToken } from "../services/notifications";

const colors = {
  blue: "#0b4f6c", sky: "#01baef", red: "#b80c09", canvas: "#fbfbff", ink: "#040f16", muted: "#61727a", line: "#d9e4e7", success: "#177b59"
};

const serviceIcons = {
  medical_health_checkup: "✚", diagnostic_service: "⌁", household_help: "⌂", shopping: "▧",
  transport: "◌", companion_visit: "♡", digital_assistance: "▣"
};

const phoneCountryCodes = [
  ["India", "+91"], ["United States / Canada", "+1"], ["United Kingdom", "+44"],
  ["Australia", "+61"], ["Singapore", "+65"], ["United Arab Emirates", "+971"]
];
const supportedLanguages = ["English", "Telugu", "Hindi", "Spanish", "Chinese (Mandarin)", "Arabic", "French", "German", "Portuguese", "Japanese", "Korean"];

const dateTimeLabel = (value) => value ? new Date(value).toLocaleString(undefined, { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" }) : "Time to be arranged";

function mergePickerValue(current, selected, mode) {
  const merged = new Date(current);
  if (mode === "date") merged.setFullYear(selected.getFullYear(), selected.getMonth(), selected.getDate());
  else merged.setHours(selected.getHours(), selected.getMinutes(), 0, 0);
  return merged;
}

function ActionButton({ children, onPress, secondary = false }) {
  return <TouchableOpacity accessibilityRole="button" onPress={onPress} style={[styles.actionButton, secondary && styles.secondaryButton]}><Text style={[styles.actionButtonText, secondary && styles.secondaryButtonText]}>{children}</Text></TouchableOpacity>;
}

function ModalSheet({ visible, title, children, onClose }) {
  return <Modal visible={visible} animationType="slide" transparent onRequestClose={onClose}>
    <View style={styles.modalBackdrop}><View style={styles.sheet}>
      <View style={styles.sheetHandle} />
      <View style={styles.sheetHeading}><Text style={styles.sheetTitle}>{title}</Text><TouchableOpacity accessibilityLabel="Close" onPress={onClose}><Text style={styles.close}>×</Text></TouchableOpacity></View>
      {children}
    </View></View>
  </Modal>;
}

function AddressAutocomplete({ onSelected }) {
  const [address, setAddress] = useState("");
  const [suggestions, setSuggestions] = useState([]);
  const [error, setError] = useState("");
  const searchTimerRef = useRef(null);
  const sessionTokenRef = useRef(`goldenly${Date.now()}${Math.random().toString(36).slice(2)}`);

  useEffect(() => () => clearTimeout(searchTimerRef.current), []);

  const search = (value) => {
    setAddress(value); setError("");
    clearTimeout(searchTimerRef.current);
    if (value.trim().length < 3) return setSuggestions([]);
    searchTimerRef.current = setTimeout(async () => {
      try { setSuggestions((await searchPlaces(value.trim(), sessionTokenRef.current)).suggestions || []); }
      catch (requestError) { setError(requestError.message); setSuggestions([]); }
    }, 300);
  };
  const select = async (placeId) => {
    try {
      const place = (await getPlace(placeId, sessionTokenRef.current)).place;
      setAddress(place.address || ""); setSuggestions([]); onSelected(place);
    } catch (requestError) { setError(requestError.message); }
  };

  return <View style={styles.addressPicker}><TextInput value={address} onChangeText={search} style={styles.authInput} placeholder="Home address" placeholderTextColor={colors.muted} autoComplete="street-address" />{suggestions.map((suggestion) => <TouchableOpacity key={suggestion.place_id} accessibilityRole="button" onPress={() => select(suggestion.place_id)} style={styles.addressSuggestion}><Text style={styles.addressSuggestionText}>{suggestion.text}</Text></TouchableOpacity>)}{suggestions.length ? <Text style={styles.googleAttribution}>Powered by Google</Text> : null}{error ? <Text style={styles.authError}>{error}</Text> : null}</View>;
}

function AuthenticationScreen({ onAuthenticated }) {
  const [mode, setMode] = useState("signIn");
  const [step, setStep] = useState("details");
  const [identifier, setIdentifier] = useState("");
  const [identifierType, setIdentifierType] = useState("email");
  const [phoneCountryCode, setPhoneCountryCode] = useState("+91");
  const [phoneNumber, setPhoneNumber] = useState("");
  const [code, setCode] = useState("");
  const [fullName, setFullName] = useState("");
  const [country, setCountry] = useState("");
  const [place, setPlace] = useState(null);
  const [memberName, setMemberName] = useState("");
  const [preferredLanguage, setPreferredLanguage] = useState("English");
  const [setupFor, setSetupFor] = useState("self");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const selectedIdentifier = () => identifierType === "phone" ? `${phoneCountryCode}${phoneNumber.replace(/\D/g, "")}` : identifier.trim();

  const sendCode = async () => {
    setBusy(true); setError("");
    try { const value = selectedIdentifier(); await requestCode(value); setIdentifier(value); setStep("code"); } catch (requestError) { setError(requestError.message); } finally { setBusy(false); }
  };
  const verify = async () => {
    setBusy(true); setError("");
    try {
      const placeAttributes = place ? { address: place.address, location: place.city, city: place.city, region: place.region, country: place.country || country, country_code: place.country_code, postal_code: place.postal_code, latitude: place.latitude, longitude: place.longitude, google_place_id: place.place_id } : { country };
      const result = mode === "signIn" ? await signIn(identifier, code) : await signUp({ identifier, code, setup_for: setupFor === "self" ? "self" : "someone_else", relationship_to_person: setupFor === "self" ? "self" : "family", consent_basis: setupFor === "self" ? undefined : "Coordinator confirmed initial setup", user: { full_name: fullName, ...placeAttributes }, care_profile: { full_name: memberName, preferred_language: preferredLanguage, ...placeAttributes } });
      const sessionUser = { ...result.user, care_profiles: result.care_profiles || [], active_care_profile_id: result.active_care_profile_id };
      await saveSession(result.user, result.tokens, { care_profiles: sessionUser.care_profiles, active_care_profile_id: sessionUser.active_care_profile_id });
      onAuthenticated(sessionUser);
    } catch (requestError) { setError(requestError.message); } finally { setBusy(false); }
  };
  const switchMode = (nextMode) => { setMode(nextMode); setStep("details"); setCode(""); setError(""); };

  return <SafeAreaView style={styles.safe}><StatusBar style="dark" /><ScrollView contentContainerStyle={styles.authScreen} keyboardShouldPersistTaps="handled">
    <Image source={require("../assets/goldenly-app-icon.png")} style={brandingStyles.mobileLogo} /><Text style={styles.authLabel}>GOLDENLY</Text>
    <Text style={styles.authTitle}>{mode === "signIn" ? "Welcome back" : "Create your account"}</Text>
    <Text style={styles.authIntro}>{step === "code" ? `Enter the code sent to ${identifier}.` : "Use your email address or phone number to securely continue."}</Text>
    <View style={styles.modeRow}><TouchableOpacity onPress={() => switchMode("signIn")} style={[styles.modeButton, mode === "signIn" && styles.modeButtonActive]}><Text style={[styles.modeText, mode === "signIn" && styles.modeTextActive]}>Sign in</Text></TouchableOpacity><TouchableOpacity onPress={() => switchMode("signUp")} style={[styles.modeButton, mode === "signUp" && styles.modeButtonActive]}><Text style={[styles.modeText, mode === "signUp" && styles.modeTextActive]}>Sign up</Text></TouchableOpacity></View>
    {step === "details" ? <View style={styles.authForm}>{mode === "signUp" && <><TextInput value={fullName} onChangeText={setFullName} style={styles.authInput} placeholder="Your name" placeholderTextColor={colors.muted} /><AddressAutocomplete onSelected={(selectedPlace) => { setPlace(selectedPlace); setCountry(selectedPlace.country || ""); }} /><TextInput value={country} onChangeText={setCountry} style={styles.authInput} placeholder="Country" placeholderTextColor={colors.muted} /><View style={styles.modeRow}><TouchableOpacity onPress={() => setSetupFor("self")} style={[styles.modeButton, setupFor === "self" && styles.modeButtonActive]}><Text style={[styles.modeText, setupFor === "self" && styles.modeTextActive]}>For myself</Text></TouchableOpacity><TouchableOpacity onPress={() => setSetupFor("someoneElse")} style={[styles.modeButton, setupFor === "someoneElse" && styles.modeButtonActive]}><Text style={[styles.modeText, setupFor === "someoneElse" && styles.modeTextActive]}>For someone else</Text></TouchableOpacity></View><TextInput value={memberName} onChangeText={setMemberName} style={styles.authInput} placeholder={setupFor === "self" ? "Your care profile name" : "Person’s care profile name"} placeholderTextColor={colors.muted} /><Text style={styles.authFieldLabel}>Preferred language</Text><ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.phoneCodeRow}>{supportedLanguages.map((language) => <TouchableOpacity key={language} accessibilityRole="button" onPress={() => setPreferredLanguage(language)} style={[styles.phoneCode, preferredLanguage === language && styles.phoneCodeActive]}><Text style={[styles.phoneCodeText, preferredLanguage === language && styles.phoneCodeTextActive]}>{language}</Text></TouchableOpacity>)}</ScrollView></>}<View style={styles.modeRow}><TouchableOpacity onPress={() => setIdentifierType("email")} style={[styles.modeButton, identifierType === "email" && styles.modeButtonActive]}><Text style={[styles.modeText, identifierType === "email" && styles.modeTextActive]}>Email</Text></TouchableOpacity><TouchableOpacity onPress={() => setIdentifierType("phone")} style={[styles.modeButton, identifierType === "phone" && styles.modeButtonActive]}><Text style={[styles.modeText, identifierType === "phone" && styles.modeTextActive]}>Phone</Text></TouchableOpacity></View>{identifierType === "email" ? <TextInput value={identifier} onChangeText={setIdentifier} style={styles.authInput} placeholder="Email address" placeholderTextColor={colors.muted} autoCapitalize="none" autoCorrect={false} keyboardType="email-address" /> : <><ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.phoneCodeRow}>{phoneCountryCodes.map(([name, dialCode]) => <TouchableOpacity key={dialCode} accessibilityRole="button" onPress={() => setPhoneCountryCode(dialCode)} style={[styles.phoneCode, phoneCountryCode === dialCode && styles.phoneCodeActive]}><Text style={[styles.phoneCodeText, phoneCountryCode === dialCode && styles.phoneCodeTextActive]}>{name} {dialCode}</Text></TouchableOpacity>)}</ScrollView><View style={styles.phoneInputRow}><Text style={styles.phonePrefix}>{phoneCountryCode}</Text><TextInput value={phoneNumber} onChangeText={setPhoneNumber} style={styles.phoneInput} placeholder="Phone number" placeholderTextColor={colors.muted} keyboardType="phone-pad" autoComplete="tel" /></View></>}{error ? <Text style={styles.authError}>{error}</Text> : null}<ActionButton onPress={sendCode}>{busy ? "Sending…" : "Send verification code"}</ActionButton></View> : <View style={styles.authForm}><TextInput value={code} onChangeText={setCode} style={styles.authInput} placeholder="Verification code" placeholderTextColor={colors.muted} keyboardType="number-pad" autoComplete="one-time-code" />{error ? <Text style={styles.authError}>{error}</Text> : null}<ActionButton onPress={verify}>{busy ? "Verifying…" : mode === "signIn" ? "Verify and sign in" : "Verify and create account"}</ActionButton><TouchableOpacity onPress={() => setStep("details")}><Text style={styles.changeIdentifier}>Use a different email or phone number</Text></TouchableOpacity></View>}
    <Text style={styles.authSafety}>Goldenly uses one-time codes to protect your account. We do not ask for a password in the mobile app.</Text>
  </ScrollView></SafeAreaView>;
}

export default function Home() {
  const [user, setUser] = useState(null);
  const [authReady, setAuthReady] = useState(false);
  const [profilePickerOpen, setProfilePickerOpen] = useState(false);
  const [tab, setTab] = useState("Today");
  const [tasks, setTasks] = useState([]);
  const [careDashboard, setCareDashboard] = useState({ reminders: [], service_requests: [] });
  const [serviceCatalogs, setServiceCatalogs] = useState([]);
  const [trustedCircle, setTrustedCircle] = useState([]);
  const [careDataBusy, setCareDataBusy] = useState(false);
  const [notificationMode, setNotificationMode] = useState("unknown");
  const [selectedHelp, setSelectedHelp] = useState(null);
  const [serviceDateTime, setServiceDateTime] = useState(() => new Date(Date.now() + 60 * 60 * 1000));
  const [serviceNotes, setServiceNotes] = useState("");
  const [servicePickerMode, setServicePickerMode] = useState(null);
  const [requestSaved, setRequestSaved] = useState(false);
  const [assistantOpen, setAssistantOpen] = useState(false);
  const [message, setMessage] = useState("");
  const [assistantReply, setAssistantReply] = useState("");
  const [assistantMessages, setAssistantMessages] = useState([]);
  const [assistantProposal, setAssistantProposal] = useState(null);
  const [assistantConversationToken, setAssistantConversationToken] = useState(null);
  const [assistantBusy, setAssistantBusy] = useState(false);
  const [assistantLanguage, setAssistantLanguage] = useState("English");
  const [assistantVoice, setAssistantVoice] = useState(null);
  const [listening, setListening] = useState(false);
  const [speaking, setSpeaking] = useState(false);
  const [sosOpen, setSosOpen] = useState(false);
  const [shareLocation, setShareLocation] = useState(false);
  const [sosProposal, setSosProposal] = useState(null);
  const [sosBusy, setSosBusy] = useState(false);
  const [careSection, setCareSection] = useState("Medicines");
  const assistantOpenRef = useRef(assistantOpen);
  const assistantProposalRef = useRef(assistantProposal);
  const greetingPlayedRef = useRef(false);
  const startListeningRef = useRef(null);
  const speakToMemberRef = useRef(null);
  const sendMessageRef = useRef(null);
  const confirmAssistantProposalRef = useRef(null);
  const voiceTurnRef = useRef(0);
  const chatScrollRef = useRef(null);
  const chatMessageSequenceRef = useRef(0);

  const nextChatMessageId = (role) => `${role}-${++chatMessageSequenceRef.current}`;

  assistantOpenRef.current = assistantOpen;
  assistantProposalRef.current = assistantProposal;

  const configureSpeakerOutput = () => {
    if (Platform.OS !== "ios") return;

    try {
      forceSpeakerOutput();
    } catch (error) {
      // The system speech module provides a fallback if the device rejects a
      // route change during an interruption.
    }
  };

  const startListening = async () => {
    try {
      if (!assistantOpenRef.current || assistantBusy) return;
      if (!ExpoSpeechRecognitionModule.isRecognitionAvailable()) {
        setAssistantReply("Voice input is not available on this device. You can still type your request.");
        return;
      }

      const permission = await ExpoSpeechRecognitionModule.requestPermissionsAsync();
      if (!permission.granted) {
        setAssistantReply("Please allow microphone and speech-recognition access to speak with Goldenly.");
        return;
      }

      ExpoSpeechRecognitionModule.start({ lang: assistantLanguage === "Telugu" ? "te-IN" : "en-IN", interimResults: true, continuous: false, maxAlternatives: 1, iosTaskHint: "dictation" });
    } catch (error) {
      setListening(false);
      setAssistantReply("Voice input could not start. Please rebuild the app after granting microphone and speech-recognition permissions, or type your request.");
    }
  };
  startListeningRef.current = startListening;

  const speakToMember = (text, { listenAfter = false, closeAfter = false } = {}) => {
    if (!text) return;
    const voiceTurn = ++voiceTurnRef.current;
    ExpoSpeechRecognitionModule.stop();
    setListening(false);
    Speech.stop();
    configureSpeakerOutput();
    setSpeaking(true);
    Speech.speak(text, {
      language: assistantLanguage === "Telugu" ? "te-IN" : "en-IN",
      voice: assistantVoice || undefined,
      pitch: 1.02,
      rate: 0.96,
      // The native Goldenly module puts iOS into a media-playback session before
      // each utterance, avoiding the call-style receiver used for microphone input.
      useApplicationAudioSession: true,
      onStart: () => {
        configureSpeakerOutput();
        setTimeout(() => {
          if (voiceTurn === voiceTurnRef.current) configureSpeakerOutput();
        }, 180);
      },
      onDone: () => {
        if (voiceTurn !== voiceTurnRef.current) return;
        setSpeaking(false);
        if (closeAfter) {
          setAssistantConversationToken(null);
          setAssistantProposal(null);
          setAssistantOpen(false);
          return;
        }
        if (listenAfter && assistantOpenRef.current) startListeningRef.current?.();
      },
      onError: () => {
        if (voiceTurn !== voiceTurnRef.current) return;
        setSpeaking(false);
        if (closeAfter) {
          setAssistantConversationToken(null);
          setAssistantProposal(null);
          setAssistantOpen(false);
          return;
        }
        setAssistantReply("I could not speak that response aloud. You can read it here or try again.");
      }
    });
  };
  speakToMemberRef.current = speakToMember;

  useSpeechRecognitionEvent("start", () => setListening(true));
  useSpeechRecognitionEvent("end", () => setListening(false));
  useSpeechRecognitionEvent("result", (event) => {
    const transcript = event.results?.[0]?.transcript?.trim();
    if (!transcript) return;
    setMessage(transcript);
    if (!event.isFinal) return;

    const isConfirmation = /^(confirm|yes|please do|go ahead|do it|avunu|అవును|నిర్ధారించండి)/i.test(transcript);
    if (assistantProposalRef.current && isConfirmation) {
      confirmAssistantProposalRef.current?.();
    } else {
      sendMessageRef.current?.(transcript);
    }
  });
  useSpeechRecognitionEvent("error", (event) => {
    setListening(false);
    if (event.error !== "aborted") setAssistantReply("I could not hear that. Please try again or type your request.");
  });

  useEffect(() => { getSession().then(setUser).finally(() => setAuthReady(true)); }, []);
  useEffect(() => {
    if (!user) return;

    let active = true;
    registerForRemoteNotifications().then(async (token) => {
      if (!token) return active && setNotificationMode("local");

      await registerPushToken(token, Platform.OS);
      if (active) {
        await cancelLocalCareNotifications();
        setNotificationMode("push");
      }
    }).catch(() => {
      if (active) setNotificationMode("local");
    });

    return () => { active = false; };
  }, [user?.id]);
  useEffect(() => {
    let active = true;
    const languagePrefix = assistantLanguage === "Telugu" ? "te" : "en";

    Speech.getAvailableVoicesAsync().then((voices) => {
      if (!active) return;
      const matchesLanguage = voices.filter((voice) => voice.language.toLowerCase().startsWith(languagePrefix));
      const enhancedVoice = matchesLanguage.find((voice) => voice.quality === "Enhanced");
      setAssistantVoice((enhancedVoice || matchesLanguage[0])?.identifier || null);
    }).catch(() => {
      if (active) setAssistantVoice(null);
    });

    return () => { active = false; };
  }, [assistantLanguage]);
  useEffect(() => {
    if (!assistantOpen) {
      greetingPlayedRef.current = false;
      voiceTurnRef.current += 1;
      Speech.stop();
      ExpoSpeechRecognitionModule.stop();
      setListening(false);
      setSpeaking(false);
      return;
    }
    if (!user || greetingPlayedRef.current) return;

    greetingPlayedRef.current = true;
    const greeting = assistantLanguage === "Telugu"
      ? "నమస్కారం, నేను గోల్డెన్లీ. నేను మీకు ఏమి చేయగలను?"
      : "Hello, I am Goldenly. What can I do for you today?";
    setAssistantMessages([{ id: nextChatMessageId("goldenly"), role: "assistant", text: greeting }]);
    speakToMemberRef.current?.(greeting, { listenAfter: true });
  }, [assistantOpen, user]);
  useEffect(() => () => Speech.stop(), []);

  const careProfiles = user?.care_profiles || [];
  const activeCareProfile = careProfiles.find((profile) => profile.id === user?.active_care_profile_id) || careProfiles[0];
  const handleExpiredSession = async () => {
    await disableNotifications();
    await clearTokens();
    setAssistantOpen(false);
    setAssistantProposal(null);
    setAssistantConversationToken(null);
    setUser(null);
    Alert.alert("Session ended", "Please sign in again to continue.");
  };
  const loadCareData = async () => {
    if (!activeCareProfile?.id) return;
    setCareDataBusy(true);
    try {
      const dashboard = await fetchDashboard(activeCareProfile.id);
      setCareDashboard({ reminders: dashboard.reminders || [], service_requests: dashboard.service_requests || [] });
      setServiceCatalogs(dashboard.service_catalogs || []);
      setTasks([
        ...dashboard.reminders.map((reminder) => ({ id: `reminder-${reminder.id}`, icon: "◷", title: reminder.title, detail: reminder.recurrence || "One-time reminder", time: new Date(reminder.scheduled_for).toLocaleString(undefined, { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" }), kind: "reminder", done: reminder.status === "completed" })),
        ...dashboard.service_requests.map((request) => ({ id: `service-${request.id}`, icon: serviceIcons[request.service_kind] || "✦", title: request.service_name || request.service_type, detail: request.status.replaceAll("_", " "), time: dateTimeLabel(request.preferred_time), kind: "service", done: request.status === "completed" }))
      ]);
      setTrustedCircle(dashboard.trusted_circle || []);
      if (notificationMode === "local") {
        await scheduleLocalCareNotifications({
          careProfileId: activeCareProfile.id,
          reminders: dashboard.reminders || [],
          serviceRequests: dashboard.service_requests || []
        });
      }
    } catch (error) {
      if (error.message.includes("session has ended")) handleExpiredSession();
    } finally {
      setCareDataBusy(false);
    }
  };
  const disableNotifications = async () => {
    const token = await storedPushToken();
    try { await unregisterPushToken(token); } catch (_) { /* The stored token is still cleared on sign-out. */ }
    await clearStoredPushToken();
    await cancelLocalCareNotifications();
    setNotificationMode("unknown");
  };
  useEffect(() => { loadCareData(); }, [activeCareProfile?.id, notificationMode]);

  if (!authReady) return <SafeAreaView style={styles.loading}><ActivityIndicator color={colors.blue} size="large" /></SafeAreaView>;
  if (!user) return <AuthenticationScreen onAuthenticated={setUser} />;

  const date = new Intl.DateTimeFormat(undefined, { weekday: "long", month: "long", day: "numeric" }).format(new Date());
  const pendingCount = tasks.filter((task) => !task.done).length;
  const openAssistant = () => {
    greetingPlayedRef.current = false;
    setAssistantConversationToken(null);
    setAssistantReply("");
    setAssistantProposal(null);
    setAssistantMessages([]);
    setAssistantOpen(true);
  };
  const sendMessage = async (messageToSend = message) => {
    const prompt = messageToSend.trim();
    if (!prompt || assistantBusy) return;
    Keyboard.dismiss();
    Speech.stop();
    setSpeaking(false);
    setMessage("");
    setAssistantMessages((messages) => [...messages, { id: nextChatMessageId("member"), role: "member", text: prompt }]);
    const isFarewell = /(?:^|\s)(bye|goodbye|see you|talk to you later|tata|బై|వీడ్కోలు)(?:\s|$)/i.test(prompt);
    if (isFarewell) {
      const farewell = assistantLanguage === "Telugu" ? "సరే, మళ్ళీ మాట్లాడుదాం. జాగ్రత్తగా ఉండండి." : "Goodbye for now. Take care, and I am here whenever you need me.";
      setAssistantReply(farewell);
      setAssistantProposal(null);
      setAssistantConversationToken(null);
      setAssistantMessages((messages) => [...messages, { id: nextChatMessageId("goldenly"), role: "assistant", text: farewell }]);
      speakToMemberRef.current?.(farewell, { closeAfter: true });
      return;
    }
    setAssistantBusy(true); setAssistantProposal(null);
    try {
      const result = await askCareAgent(prompt, activeCareProfile?.id, assistantConversationToken);
      setAssistantReply(result.reply); setAssistantProposal(result.proposal);
      setAssistantConversationToken(result.conversation_token || null);
      setAssistantMessages((messages) => [...messages, { id: nextChatMessageId("goldenly"), role: "assistant", text: result.reply }]);
      const spokenReply = result.proposal ? `${result.reply} ${result.proposal.confirmation}` : result.reply;
      speakToMemberRef.current?.(spokenReply, { listenAfter: !result.proposal });
    } catch (error) {
      if (error.code === "SESSION_EXPIRED") return handleExpiredSession();
      setAssistantReply(error.message);
      setAssistantMessages((messages) => [...messages, { id: nextChatMessageId("goldenly"), role: "assistant", text: error.message }]);
    }
    finally { setAssistantBusy(false); }
  };
  sendMessageRef.current = sendMessage;
  const confirmAssistantProposal = async () => {
    if (!assistantProposal) return;
    setAssistantBusy(true);
    try {
      const result = await confirmCareAction(assistantProposal.confirmation_token, shareLocation, activeCareProfile?.id);
      setAssistantReply(result.message); setAssistantProposal(null); setAssistantConversationToken(null);
      setAssistantMessages((messages) => [...messages, { id: nextChatMessageId("goldenly"), role: "assistant", text: result.message }]);
      await loadCareData();
      speakToMemberRef.current?.(result.message, { listenAfter: true });
    } catch (error) {
      if (error.code === "SESSION_EXPIRED") return handleExpiredSession();
      setAssistantReply(error.message);
    }
    finally { setAssistantBusy(false); }
  };
  confirmAssistantProposalRef.current = confirmAssistantProposal;
  const toggleListening = async () => {
    try {
      if (listening) return ExpoSpeechRecognitionModule.stop();
      await startListening();
    } catch (error) {
      setListening(false);
      setAssistantReply("Voice input could not start. Please rebuild the app after granting microphone and speech-recognition permissions, or type your request.");
    }
  };
  const confirmHelp = async () => {
    if (!selectedHelp || !activeCareProfile?.id) return;
    try {
      await createServiceRequest({ service_catalog_id: selectedHelp.id, preferred_time: serviceDateTime.toISOString(), notes: serviceNotes.trim() }, activeCareProfile.id);
      setRequestSaved(true); setSelectedHelp(null); loadCareData();
    } catch (error) {
      Alert.alert("Request not saved", error.message);
    }
  };
  const prepareSos = async () => {
    setSosBusy(true);
    try { const result = await askCareAgent("SOS emergency help", activeCareProfile?.id); setSosProposal(result.proposal); }
    catch (error) {
      if (error.code === "SESSION_EXPIRED") return handleExpiredSession();
      Alert.alert("Emergency help", error.message);
    }
    finally { setSosBusy(false); }
  };
  const confirmSos = async () => {
    if (!sosProposal) return;
    setSosBusy(true);
    try {
      const result = await confirmCareAction(sosProposal.confirmation_token, shareLocation, activeCareProfile?.id);
      setSosProposal(null); setSosOpen(false);
      Alert.alert("Emergency alert recorded", result.message, result.emergency_call_url ? [{ text: "Call emergency services", onPress: () => Linking.openURL(result.emergency_call_url) }, { text: "Close" }] : undefined);
    } catch (error) {
      if (error.code === "SESSION_EXPIRED") return handleExpiredSession();
      Alert.alert("Emergency help", error.message);
    }
    finally { setSosBusy(false); }
  };
  const callPhone = (phone) => Linking.openURL(`tel:${phone.replace(/[^+\d]/g, "")}`);
  const emailProvider = (email) => Linking.openURL(`mailto:${email}`);

  const renderToday = () => <>
    <Text style={styles.pageTitle}>Today</Text><Text style={styles.date}>{date}</Text>
    <View style={styles.wellbeing}><Text style={styles.wellbeingIcon}>♡</Text><View style={styles.flex}><Text style={styles.wellbeingTitle}>You’re doing well today</Text><Text style={styles.detail}>You have {pendingCount} things left in your plan.</Text></View></View>
    <Text style={styles.sectionTitle}>Your plan</Text>
    {careDataBusy ? <ActivityIndicator color={colors.blue} /> : null}
    <View style={styles.cards}>{tasks.map((task) => <View key={task.id} style={styles.task}>
      <Text style={styles.taskIcon}>{task.icon}</Text><View style={styles.flex}><Text style={[styles.cardTitle, task.done && styles.completedText]}>{task.title}</Text><Text style={styles.detail}>{task.detail}</Text><Text style={styles.time}>{task.time}</Text></View>
      {task.done ? <View style={styles.donePill}><Text style={styles.doneText}>Done ✓</Text></View> : <View style={styles.donePill}><Text style={styles.doneText}>{task.kind === "service" ? "Requested" : "Scheduled"}</Text></View>}
    </View>)}</View>
    {!careDataBusy && tasks.length === 0 ? <Text style={styles.detail}>No reminders or service requests have been recorded for this care profile yet.</Text> : null}
  </>;

  const renderHelp = () => <>
    <Text style={styles.pageTitle}>Get help</Text><Text style={styles.date}>Choose what you need. You will confirm before we send a request.</Text>
    {requestSaved && <View style={styles.confirmation}><Text style={styles.confirmationTitle}>Request confirmed</Text><Text style={styles.detail}>Provider matching is the next phase.</Text></View>}
    <View style={styles.cards}>{serviceCatalogs.map((service) => <TouchableOpacity key={service.id} accessibilityRole="button" onPress={() => { setRequestSaved(false); setServiceDateTime(new Date(Date.now() + 60 * 60 * 1000)); setServiceNotes(""); setSelectedHelp(service); }} style={styles.helpCard}><Text style={styles.helpIcon}>{serviceIcons[service.kind] || "✦"}</Text><View style={styles.flex}><Text style={styles.cardTitle}>{service.name}</Text><Text style={styles.detail}>{service.description}</Text></View><Text style={styles.chevron}>›</Text></TouchableOpacity>)}</View>
    {!careDataBusy && serviceCatalogs.length === 0 ? <Text style={styles.detail}>Services are loading. Please try again shortly.</Text> : null}
  </>;

  const renderAssignedProvider = (provider) => {
    if (!provider) return null;

    return <View style={styles.providerCard}>
      <View style={styles.contactAvatar}><Text style={styles.contactAvatarText}>{provider.name?.[0] || "G"}</Text></View>
      <View style={styles.flex}>
        <Text style={styles.providerLabel}>ASSIGNED CARE PARTNER</Text>
        <Text style={styles.cardTitle}>{provider.name}</Text>
        {provider.location ? <Text style={styles.detail}>{provider.location}</Text> : null}
        {provider.phone_number ? <Text style={styles.detail}>{provider.phone_number}</Text> : provider.email_address ? <Text style={styles.detail}>{provider.email_address}</Text> : null}
      </View>
      <View style={styles.providerActions}>
        {provider.phone_number ? <TouchableOpacity accessibilityRole="button" accessibilityLabel={`Call ${provider.name}`} onPress={() => callPhone(provider.phone_number)} style={styles.providerAction}><Text style={styles.providerActionText}>Call</Text></TouchableOpacity> : null}
        {provider.email_address ? <TouchableOpacity accessibilityRole="button" accessibilityLabel={`Email ${provider.name}`} onPress={() => emailProvider(provider.email_address)} style={styles.providerAction}><Text style={styles.providerActionText}>Email</Text></TouchableOpacity> : null}
      </View>
    </View>;
  };

  const renderCare = () => <>
    <Text style={styles.pageTitle}>My care</Text><Text style={styles.date}>Your health and care information</Text>
    <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.segmentRow}>{["Medicines", "Appointments", "Documents", "Services"].map((item) => <TouchableOpacity key={item} onPress={() => setCareSection(item)} style={[styles.segment, careSection === item && styles.segmentActive]}><Text style={[styles.segmentText, careSection === item && styles.segmentTextActive]}>{item}</Text></TouchableOpacity>)}</ScrollView>
    {careSection === "Medicines" && <View style={styles.infoCard}><Text style={styles.cardTitle}>Medication records</Text>{careDashboard.reminders.filter((reminder) => /medicine|tablet|medication|dose/i.test(reminder.title)).map((reminder) => <View key={reminder.id} style={styles.careRecord}><Text style={styles.cardTitle}>{reminder.title}</Text><Text style={styles.detail}>{dateTimeLabel(reminder.scheduled_for)}</Text></View>)}{!careDashboard.reminders.some((reminder) => /medicine|tablet|medication|dose/i.test(reminder.title)) ? <Text style={styles.detail}>No medication records have been added for this care profile yet.</Text> : null}<Text style={styles.safeNote}>Goldenly does not provide medication or dosage advice.</Text></View>}
    {careSection === "Appointments" && <View style={styles.infoCard}><Text style={styles.cardTitle}>Appointments and reminders</Text>{[...careDashboard.reminders, ...careDashboard.service_requests.filter((request) => request.preferred_time)].sort((left, right) => new Date(left.scheduled_for || left.preferred_time) - new Date(right.scheduled_for || right.preferred_time)).map((item) => <View key={`${item.scheduled_for ? "reminder" : "service"}-${item.id}`} style={styles.careRecord}><Text style={styles.cardTitle}>{item.service_name || item.service_type || item.title}</Text><Text style={styles.detail}>{dateTimeLabel(item.scheduled_for || item.preferred_time)} · {(item.status || "scheduled").replaceAll("_", " ")}</Text></View>)}{!careDashboard.reminders.length && !careDashboard.service_requests.some((request) => request.preferred_time) ? <Text style={styles.detail}>No appointments or reminders have been recorded yet.</Text> : null}</View>}
    {careSection === "Documents" && <View style={styles.infoCard}><Text style={styles.cardTitle}>Medical documents</Text><Text style={styles.detail}>No documents have been added for this care profile yet.</Text><Text style={styles.safeNote}>Document summaries are informational, not medical advice.</Text></View>}
    {careSection === "Services" && <View style={styles.infoCard}><Text style={styles.cardTitle}>Service requests</Text>{careDashboard.service_requests.map((request) => <View key={request.id} style={styles.careRecord}><Text style={styles.cardTitle}>{request.service_name || request.service_type}</Text><Text style={styles.detail}>{dateTimeLabel(request.preferred_time)} · {request.status.replaceAll("_", " ")}</Text>{renderAssignedProvider(request.assigned_provider)}{request.notes ? <Text style={styles.safeNote}>{request.notes}</Text> : null}</View>)}{!careDashboard.service_requests.length ? <Text style={styles.detail}>No service requests have been recorded for this care profile yet.</Text> : null}</View>}
  </>;

  const renderCircle = () => <>
    <Text style={styles.pageTitle}>My circle</Text><Text style={styles.date}>People you trust to support your care</Text>
    <View style={styles.cards}>{trustedCircle.map((contact) => <View key={contact.id} style={styles.contactCard}><View style={styles.contactAvatar}><Text style={styles.contactAvatarText}>{contact.name[0]}</Text></View><View style={styles.flex}><Text style={styles.cardTitle}>{contact.name}</Text><Text style={styles.detail}>{contact.relationship.replaceAll("_", " ")}</Text><Text style={styles.access}>{Object.keys(contact.permissions || {}).length ? "Scoped care access" : "Profile owner"}</Text></View></View>)}</View>
    {!careDataBusy && trustedCircle.length === 0 ? <Text style={styles.detail}>No other trusted-circle contacts have access to this care profile yet.</Text> : null}
    <View style={styles.permissionCard}><Text style={styles.cardTitle}>Your privacy matters</Text><Text style={styles.detail}>Access is granted per care profile and can be changed from the Goldenly web experience.</Text></View>
  </>;

  const body = tab === "Today" ? renderToday() : tab === "Help" ? renderHelp() : tab === "My Care" ? renderCare() : renderCircle();
  return <SafeAreaView style={styles.safe}><StatusBar style="dark" />
    <ScrollView contentContainerStyle={styles.screen}>{<View style={styles.top}><View><Image source={require("../assets/goldenly-app-icon.png")} style={brandingStyles.topLogo} /><Text style={styles.label}>GOLDENLY</Text></View><View><TouchableOpacity onPress={() => setProfilePickerOpen(true)} style={styles.memberBadge}><Text style={styles.memberName}>{activeCareProfile?.full_name || user.full_name}</Text><Text style={styles.memberSub}>{activeCareProfile?.id === user.active_care_profile_id ? "My care" : "Choose care profile"}</Text></TouchableOpacity><TouchableOpacity onPress={async () => { await disableNotifications(); await clearTokens(); setUser(null); }}><Text style={styles.signOutText}>Sign out</Text></TouchableOpacity></View></View>}{body}</ScrollView>
    <TouchableOpacity accessibilityRole="button" accessibilityLabel="Talk to Goldenly" onPress={openAssistant} style={styles.agentFloater}><Text style={styles.agentFloaterIcon}>🎙</Text><Text style={styles.agentFloaterText}>Talk to Goldenly</Text></TouchableOpacity>
    <View style={styles.nav}>{[["Today", "⌂"], ["Help", "✦"], ["SOS", "✚"], ["My Care", "♡"], ["My Circle", "♧"]].map(([name, icon]) => <TouchableOpacity key={name} accessibilityRole="button" accessibilityLabel={name} onPress={() => name === "SOS" ? setSosOpen(true) : setTab(name)} style={styles.navItem}><Text style={[styles.navIcon, name === "SOS" && styles.sosIcon]}>{icon}</Text><Text style={[styles.navText, tab === name && styles.activeText, name === "SOS" && styles.sosText]}>{name}</Text></TouchableOpacity>)}</View>
    <ModalSheet visible={Boolean(selectedHelp)} title={selectedHelp?.name || "Request help"} onClose={() => { setServicePickerMode(null); setSelectedHelp(null); }}><Text style={styles.sheetText}>{selectedHelp?.description}</Text><Text style={styles.cardTitle}>Preferred date and time</Text><View style={styles.dateTimeRow}><ActionButton secondary onPress={() => setServicePickerMode("date")}>{serviceDateTime.toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" })}</ActionButton><ActionButton secondary onPress={() => setServicePickerMode("time")}>{serviceDateTime.toLocaleTimeString(undefined, { hour: "numeric", minute: "2-digit" })}</ActionButton></View>{servicePickerMode ? <DateTimePicker value={serviceDateTime} mode={servicePickerMode} display="default" onChange={(_event, selected) => { setServicePickerMode(null); if (selected) setServiceDateTime((current) => mergePickerValue(current, selected, servicePickerMode)); }} /> : null}<Text style={styles.cardTitle}>Extra details (optional)</Text><TextInput value={serviceNotes} onChangeText={setServiceNotes} style={styles.input} multiline placeholder="Access needs, preferred provider, or other details" placeholderTextColor={colors.muted} /><Text style={styles.safeNote}>Goldenly will not book or dispatch anyone until you confirm.</Text><ActionButton onPress={confirmHelp}>Confirm request</ActionButton><ActionButton secondary onPress={() => setSelectedHelp(null)}>Not now</ActionButton></ModalSheet>
    <Modal visible={assistantOpen} animationType="slide" presentationStyle="fullScreen" onRequestClose={() => { Keyboard.dismiss(); setAssistantConversationToken(null); setAssistantOpen(false); }}>
      <SafeAreaView style={styles.chatScreen}><StatusBar style="dark" />
        <KeyboardAvoidingView style={styles.flex} behavior={Platform.OS === "ios" ? "padding" : undefined}>
          <View style={styles.chatHeader}>
            <View style={styles.chatAvatar}><Text style={styles.chatAvatarText}>G</Text></View>
            <View style={styles.flex}><Text style={styles.chatKicker}>GOLDENLY AI</Text><Text style={styles.chatTitle}>Here to help {activeCareProfile?.full_name || "you"}</Text></View>
            <TouchableOpacity accessibilityLabel="Close chat" onPress={() => { Keyboard.dismiss(); setAssistantConversationToken(null); setAssistantOpen(false); }} style={styles.chatClose}><Text style={styles.chatCloseText}>×</Text></TouchableOpacity>
          </View>
          <View style={styles.chatProfileRow}>
            <Text style={styles.chatProfileText}>Supporting {activeCareProfile?.full_name || "your care profile"}</Text>
            <View style={styles.languageRow}>{["English", "Telugu"].map((item) => <TouchableOpacity key={item} accessibilityRole="button" onPress={() => setAssistantLanguage(item)} style={[styles.languageButton, assistantLanguage === item && styles.languageButtonActive]}><Text style={[styles.languageText, assistantLanguage === item && styles.languageTextActive]}>{item}</Text></TouchableOpacity>)}</View>
          </View>
          <ScrollView ref={chatScrollRef} onContentSizeChange={() => chatScrollRef.current?.scrollToEnd({ animated: true })} contentContainerStyle={styles.chatContent} keyboardShouldPersistTaps="handled">
            {assistantMessages.map((item) => <View key={item.id} style={[styles.chatBubble, item.role === "member" ? styles.memberBubble : styles.goldenlyBubble]}><Text style={[styles.chatBubbleLabel, item.role === "member" && styles.memberBubbleLabel]}>{item.role === "member" ? "YOU" : "GOLDENLY"}</Text><Text style={[styles.chatBubbleText, item.role === "member" && styles.memberBubbleText]}>{item.text}</Text></View>)}
            {assistantBusy ? <View style={[styles.chatBubble, styles.goldenlyBubble]}><Text style={styles.chatBubbleLabel}>GOLDENLY</Text><Text style={styles.chatTyping}>Thinking…</Text></View> : null}
            {assistantProposal ? <View style={styles.confirmation}><Text style={styles.confirmationTitle}>{assistantProposal.title}</Text><Text style={styles.detail}>{assistantProposal.confirmation}</Text><ActionButton onPress={confirmAssistantProposal}>{assistantBusy ? "Confirming…" : "Confirm action"}</ActionButton></View> : null}
          </ScrollView>
          <View style={styles.voiceStatus}><View style={styles.voiceStatusDot} /><View style={styles.flex}><Text style={styles.voiceStatusTitle}>{speaking ? "Goldenly is speaking" : listening ? "Listening…" : "Voice conversation ready"}</Text><Text style={styles.voiceStatusCopy}>{speaking ? "I will listen when I finish." : listening ? "Speak naturally. I am listening." : "Tap the microphone to talk."}</Text></View></View>
          <View style={styles.chatComposer}>
            <View style={styles.chatInputRow}>
              <TextInput value={message} onFocus={() => { if (listening) ExpoSpeechRecognitionModule.stop(); Speech.stop(); }} onChangeText={setMessage} onSubmitEditing={() => sendMessage()} placeholder="Type a message…" placeholderTextColor={colors.muted} style={styles.chatInput} accessibilityLabel="Message Goldenly" returnKeyType="send" blurOnSubmit editable={!assistantBusy} />
              <TouchableOpacity accessibilityRole="button" accessibilityLabel="Send message" disabled={assistantBusy || !message.trim()} onPress={() => sendMessage()} style={[styles.chatSend, (assistantBusy || !message.trim()) && styles.chatSendDisabled]}><Text style={styles.chatSendText}>↑</Text></TouchableOpacity>
            </View>
            <TouchableOpacity accessibilityRole="button" accessibilityLabel={listening ? "Stop listening" : "Start voice conversation"} onPress={toggleListening} style={[styles.microphoneButton, listening && styles.microphoneButtonListening, speaking && styles.microphoneButtonSpeaking]}>
              <Text style={styles.microphoneIcon}>{listening ? "■" : "🎙"}</Text><Text style={styles.microphoneText}>{listening ? "Tap to stop listening" : speaking ? "Goldenly is speaking" : "Tap to talk"}</Text>
            </TouchableOpacity>
            <Text style={styles.safeNote}>Goldenly does not provide medical diagnoses, treatment, or dosage changes.</Text>
          </View>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </Modal>
    <ModalSheet visible={profilePickerOpen} title="Choose care profile" onClose={() => setProfilePickerOpen(false)}>{careProfiles.map((profile) => <ActionButton key={profile.id} secondary={profile.id !== activeCareProfile?.id} onPress={async () => { const updatedUser = await setActiveCareProfile(profile.id); setUser(updatedUser); setProfilePickerOpen(false); setAssistantReply(""); setAssistantProposal(null); setAssistantConversationToken(null); }}>{profile.id === activeCareProfile?.id ? `${profile.full_name} · selected` : profile.full_name}</ActionButton>)}{careProfiles.length === 0 ? <Text style={styles.detail}>Your care profile will appear here after you sign in again.</Text> : null}</ModalSheet>
    <ModalSheet visible={sosOpen} title="Emergency SOS" onClose={() => { setSosOpen(false); setSosProposal(null); }}><Text style={styles.sheetText}>After confirmation, Goldenly records an alert for your trusted circle. Use the call button for immediate emergency help.</Text><View style={styles.locationRow}><View style={styles.flex}><Text style={styles.cardTitle}>Share my saved location</Text><Text style={styles.detail}>Only if you consent</Text></View><Switch value={shareLocation} onValueChange={setShareLocation} trackColor={{ false: colors.line, true: colors.sky }} /></View><Text style={styles.safeNote}>For immediate danger, call local emergency services first.</Text>{sosProposal ? <><View style={styles.confirmation}><Text style={styles.confirmationTitle}>{sosProposal.title}</Text><Text style={styles.detail}>{sosProposal.confirmation}</Text></View><ActionButton onPress={confirmSos}>{sosBusy ? "Confirming…" : "Confirm emergency alert"}</ActionButton><ActionButton secondary onPress={() => Linking.openURL(`tel:${sosProposal.emergency_number}`)}>Call {sosProposal.emergency_number} now</ActionButton></> : <ActionButton onPress={prepareSos}>{sosBusy ? "Preparing…" : "Continue to confirmation"}</ActionButton>}<ActionButton secondary onPress={() => setSosOpen(false)}>Cancel</ActionButton></ModalSheet>
  </SafeAreaView>;
}

const styles = StyleSheet.create({
  loading: { flex: 1, alignItems: "center", justifyContent: "center", backgroundColor: colors.canvas }, authScreen: { flexGrow: 1, justifyContent: "center", padding: 28 }, authBrand: { color: colors.blue, textAlign: "center", fontSize: 43 }, authLabel: { color: colors.blue, textAlign: "center", fontSize: 11, fontWeight: "800", letterSpacing: 2, marginBottom: 34 }, authTitle: { color: colors.ink, fontSize: 29, fontWeight: "800" }, authIntro: { color: colors.muted, fontSize: 14, lineHeight: 20, marginTop: 8, marginBottom: 20 }, modeRow: { flexDirection: "row", gap: 8, marginBottom: 18 }, modeButton: { flex: 1, alignItems: "center", paddingVertical: 10, borderRadius: 9, backgroundColor: "#edf2f3" }, modeButtonActive: { backgroundColor: colors.blue }, modeText: { color: colors.muted, fontSize: 13, fontWeight: "800" }, modeTextActive: { color: "white" }, authForm: { gap: 10 }, authInput: { minHeight: 48, borderWidth: 1, borderColor: colors.line, borderRadius: 10, paddingHorizontal: 12, color: colors.ink, fontSize: 14, backgroundColor: "white" }, authError: { color: colors.red, fontSize: 12, lineHeight: 17 }, changeIdentifier: { color: colors.blue, textAlign: "center", fontSize: 12, fontWeight: "800", padding: 10 }, authSafety: { color: colors.muted, fontSize: 11, lineHeight: 16, textAlign: "center", marginTop: 24 },
  safe: { flex: 1, backgroundColor: colors.canvas }, screen: { padding: 22, paddingBottom: 108 }, flex: { flex: 1 }, top: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 27 }, brand: { color: colors.blue, fontSize: 32, lineHeight: 32 }, label: { color: colors.blue, fontWeight: "800", fontSize: 10, letterSpacing: 1.8, marginTop: 3 }, memberBadge: { paddingHorizontal: 11, paddingVertical: 7, borderRadius: 12, backgroundColor: "#e9f3f7" }, memberName: { color: colors.blue, fontSize: 13, fontWeight: "800" }, memberSub: { color: colors.muted, fontSize: 10, marginTop: 1 }, pageTitle: { color: colors.ink, fontSize: 31, fontWeight: "800", letterSpacing: -1 }, date: { color: colors.muted, fontSize: 14, marginTop: 5, marginBottom: 22, lineHeight: 20 }, sectionTitle: { color: colors.ink, fontWeight: "800", fontSize: 17, marginBottom: 10 }, wellbeing: { backgroundColor: "#e9f5f7", padding: 16, borderRadius: 16, flexDirection: "row", gap: 12, alignItems: "center", marginBottom: 22 }, wellbeingIcon: { color: colors.blue, fontSize: 29 }, wellbeingTitle: { color: colors.blue, fontSize: 16, fontWeight: "800" }, cards: { gap: 12 }, task: { backgroundColor: "white", borderWidth: 1, borderColor: colors.line, borderRadius: 15, padding: 15, flexDirection: "row", alignItems: "center", gap: 11 }, taskIcon: { color: colors.blue, fontSize: 22 }, cardTitle: { color: colors.ink, fontWeight: "800", fontSize: 15 }, completedText: { color: colors.muted, textDecorationLine: "line-through" }, detail: { color: colors.muted, fontSize: 12, marginTop: 3, lineHeight: 17 }, time: { color: colors.blue, fontSize: 11, fontWeight: "800", marginTop: 8 }, actionButton: { backgroundColor: colors.blue, alignItems: "center", justifyContent: "center", paddingHorizontal: 13, paddingVertical: 10, borderRadius: 9, minHeight: 40 }, actionButtonText: { color: "white", fontSize: 12, fontWeight: "800" }, secondaryButton: { backgroundColor: "#e9f3f7" }, secondaryButtonText: { color: colors.blue }, donePill: { backgroundColor: "#e5f5ed", paddingHorizontal: 9, paddingVertical: 7, borderRadius: 7 }, doneText: { color: colors.success, fontSize: 11, fontWeight: "800" }, confirmation: { padding: 14, borderRadius: 13, backgroundColor: "#e5f5ed", marginBottom: 15 }, confirmationTitle: { color: colors.success, fontSize: 14, fontWeight: "800" }, helpCard: { padding: 17, backgroundColor: "white", borderRadius: 15, borderWidth: 1, borderColor: colors.line, flexDirection: "row", alignItems: "center", gap: 14, minHeight: 78 }, helpIcon: { color: colors.blue, fontSize: 23 }, chevron: { color: colors.blue, fontSize: 29 }, segmentRow: { gap: 8, paddingBottom: 18 }, segment: { paddingHorizontal: 13, paddingVertical: 9, borderRadius: 20, backgroundColor: "#edf2f3" }, segmentActive: { backgroundColor: colors.blue }, segmentText: { color: colors.muted, fontSize: 12, fontWeight: "800" }, segmentTextActive: { color: "white" }, infoCard: { padding: 18, borderRadius: 16, backgroundColor: "white", borderWidth: 1, borderColor: colors.line }, careRecord: { borderTopWidth: 1, borderColor: colors.line, paddingTop: 11, marginTop: 11 }, dateTimeRow: { flexDirection: "row", gap: 9 }, safeNote: { color: colors.muted, fontSize: 11, lineHeight: 16, marginTop: 13 }, contactCard: { padding: 15, borderRadius: 15, backgroundColor: "white", borderWidth: 1, borderColor: colors.line, flexDirection: "row", alignItems: "center", gap: 11 }, contactAvatar: { width: 38, height: 38, borderRadius: 19, alignItems: "center", justifyContent: "center", backgroundColor: colors.sky }, contactAvatarText: { color: "white", fontWeight: "800" }, access: { color: colors.blue, fontSize: 10, fontWeight: "700", marginTop: 6 }, permissionCard: { marginTop: 18, padding: 16, borderRadius: 15, backgroundColor: "#e9f3f7" }, nav: { position: "absolute", bottom: 0, left: 0, right: 0, paddingVertical: 9, paddingHorizontal: 4, borderTopWidth: 1, borderColor: colors.line, backgroundColor: "white", flexDirection: "row", justifyContent: "space-around" }, navItem: { alignItems: "center", flex: 1, minHeight: 43 }, navIcon: { fontSize: 19, color: colors.blue }, navText: { fontSize: 9, color: colors.muted, marginTop: 2, textAlign: "center" }, activeText: { color: colors.blue, fontWeight: "800" }, sosIcon: { color: colors.red }, sosText: { color: colors.red, fontWeight: "800" }, modalBackdrop: { flex: 1, justifyContent: "flex-end", backgroundColor: "rgba(4,15,22,.38)" }, sheet: { backgroundColor: "white", borderTopLeftRadius: 25, borderTopRightRadius: 25, padding: 23, gap: 13 }, sheetHandle: { alignSelf: "center", width: 40, height: 4, borderRadius: 3, backgroundColor: colors.line, marginBottom: 4 }, sheetHeading: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" }, sheetTitle: { color: colors.ink, fontSize: 22, fontWeight: "800" }, close: { color: colors.muted, fontSize: 30, lineHeight: 30 }, sheetText: { color: colors.ink, fontSize: 14, lineHeight: 20 }, input: { minHeight: 88, borderWidth: 1, borderColor: colors.line, borderRadius: 11, padding: 12, color: colors.ink, fontSize: 14, textAlignVertical: "top" }, assistantReply: { padding: 12, borderRadius: 10, backgroundColor: "#e9f3f7" }, locationRow: { flexDirection: "row", alignItems: "center", gap: 12, paddingVertical: 7 }, languageRow: { flexDirection: "row", gap: 8 }, languageButton: { paddingHorizontal: 12, paddingVertical: 8, borderRadius: 18, backgroundColor: "#edf2f3" }, languageButtonActive: { backgroundColor: colors.blue }, languageText: { color: colors.muted, fontSize: 12, fontWeight: "800" }, languageTextActive: { color: "white" }, agentButtons: { flexDirection: "row", gap: 9 }, agentFloater: { position: "absolute", right: 18, bottom: 80, flexDirection: "row", alignItems: "center", gap: 8, paddingHorizontal: 16, paddingVertical: 13, borderRadius: 26, backgroundColor: colors.blue, shadowColor: "#040f16", shadowOpacity: .22, shadowRadius: 12, shadowOffset: { width: 0, height: 5 }, elevation: 7 }, agentFloaterIcon: { color: colors.sky, fontSize: 19 }, agentFloaterText: { color: "white", fontSize: 13, fontWeight: "800" }, chatScreen: { flex: 1, backgroundColor: colors.canvas }, chatHeader: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", paddingHorizontal: 22, paddingVertical: 16, borderBottomWidth: 1, borderColor: colors.line, backgroundColor: "white" }, chatKicker: { color: colors.blue, fontSize: 10, fontWeight: "800", letterSpacing: 1.4 }, chatTitle: { color: colors.ink, fontSize: 24, fontWeight: "800", marginTop: 3 }, chatClose: { width: 38, height: 38, borderRadius: 19, alignItems: "center", justifyContent: "center", backgroundColor: "#edf2f3" }, chatCloseText: { color: colors.muted, fontSize: 28, lineHeight: 30 }, chatContent: { flexGrow: 1, padding: 22, gap: 14 }, chatIntro: { color: colors.muted, fontSize: 14, lineHeight: 20 }, chatStarter: { padding: 17, borderRadius: 16, backgroundColor: "#e9f3f7" }, chatStarterTitle: { color: colors.blue, fontSize: 17, fontWeight: "800" }, chatReplyLabel: { color: colors.blue, fontSize: 10, fontWeight: "800", letterSpacing: 1.2 }, chatComposer: { paddingHorizontal: 18, paddingTop: 12, paddingBottom: 16, borderTopWidth: 1, borderColor: colors.line, backgroundColor: "white", gap: 9 }, chatInput: { minHeight: 48, borderWidth: 1, borderColor: colors.line, borderRadius: 12, paddingHorizontal: 13, color: colors.ink, fontSize: 15, backgroundColor: colors.canvas }
});

const brandingStyles = StyleSheet.create({
  mobileLogo: { alignSelf: "center", width: 76, height: 76, borderRadius: 18, marginBottom: 10 },
  topLogo: { width: 35, height: 35, borderRadius: 9, marginBottom: 3 }
});

styles.voiceStatus = { padding: 14, borderRadius: 14, backgroundColor: "#e5f5ed" };
styles.voiceStatusTitle = { color: colors.success, fontSize: 14, fontWeight: "800" };
styles.signOutText = { color: colors.muted, fontSize: 10, fontWeight: "700", textAlign: "right", marginTop: 4 };
styles.providerCard = { flexDirection: "row", alignItems: "center", gap: 10, marginTop: 11, padding: 11, borderRadius: 12, borderWidth: 1, borderColor: "#cfe5e3", backgroundColor: "#f2faf8" };
styles.providerLabel = { color: colors.blue, fontSize: 9, fontWeight: "900", letterSpacing: 1, marginBottom: 2 };
styles.providerActions = { gap: 6, alignItems: "flex-end" };
styles.providerAction = { minWidth: 54, alignItems: "center", paddingHorizontal: 9, paddingVertical: 7, borderRadius: 8, backgroundColor: colors.blue };
styles.providerActionText = { color: "white", fontSize: 10, fontWeight: "800" };

// Voice-first assistant conversation styles.
styles.chatScreen = { flex: 1, backgroundColor: "#f5f8f7" };
styles.chatHeader = { flexDirection: "row", alignItems: "center", gap: 11, paddingHorizontal: 20, paddingVertical: 14, backgroundColor: "white", borderBottomWidth: 1, borderColor: "#e5ece8" };
styles.chatAvatar = { width: 42, height: 42, borderRadius: 21, alignItems: "center", justifyContent: "center", backgroundColor: colors.blue };
styles.chatAvatarText = { color: "white", fontSize: 20, fontWeight: "900" };
styles.chatKicker = { color: colors.success, fontSize: 10, fontWeight: "900", letterSpacing: 1.4 };
styles.chatTitle = { color: colors.ink, fontSize: 17, fontWeight: "800", marginTop: 2 };
styles.chatClose = { width: 36, height: 36, borderRadius: 18, alignItems: "center", justifyContent: "center", backgroundColor: "#eef2f0" };
styles.chatCloseText = { color: colors.muted, fontSize: 27, lineHeight: 29 };
styles.chatProfileRow = { paddingHorizontal: 20, paddingVertical: 10, backgroundColor: "white", borderBottomWidth: 1, borderColor: "#e5ece8", flexDirection: "row", alignItems: "center", justifyContent: "space-between", gap: 10 };
styles.chatProfileText = { flex: 1, color: colors.muted, fontSize: 11, fontWeight: "700" };
styles.languageRow = { flexDirection: "row", gap: 5 };
styles.languageButton = { paddingHorizontal: 10, paddingVertical: 6, borderRadius: 14, backgroundColor: "#edf2f0" };
styles.languageButtonActive = { backgroundColor: colors.blue };
styles.languageText = { color: colors.muted, fontSize: 10, fontWeight: "800" };
styles.languageTextActive = { color: "white" };
styles.chatContent = { flexGrow: 1, padding: 18, gap: 11, justifyContent: "flex-end" };
styles.chatBubble = { maxWidth: "84%", paddingHorizontal: 15, paddingVertical: 12, borderRadius: 19 };
styles.goldenlyBubble = { alignSelf: "flex-start", backgroundColor: "white", borderWidth: 1, borderColor: "#dfe9e4", borderBottomLeftRadius: 5 };
styles.memberBubble = { alignSelf: "flex-end", backgroundColor: colors.blue, borderBottomRightRadius: 5 };
styles.chatBubbleLabel = { color: colors.success, fontSize: 9, fontWeight: "900", letterSpacing: 1.1, marginBottom: 4 };
styles.memberBubbleLabel = { color: "#bcecf8" };
styles.chatBubbleText = { color: colors.ink, fontSize: 15, lineHeight: 21 };
styles.memberBubbleText = { color: "white" };
styles.chatTyping = { color: colors.muted, fontSize: 14, fontStyle: "italic" };
styles.voiceStatus = { flexDirection: "row", alignItems: "center", gap: 10, marginHorizontal: 18, marginBottom: 10, padding: 12, borderRadius: 14, backgroundColor: "#e3f4eb" };
styles.voiceStatusDot = { width: 9, height: 9, borderRadius: 5, backgroundColor: colors.success };
styles.voiceStatusTitle = { color: colors.success, fontSize: 12, fontWeight: "900" };
styles.voiceStatusCopy = { color: "#537467", fontSize: 11, lineHeight: 15, marginTop: 2 };
styles.chatComposer = { paddingHorizontal: 18, paddingTop: 12, paddingBottom: 15, borderTopWidth: 1, borderColor: "#e5ece8", backgroundColor: "white", gap: 10 };
styles.chatInputRow = { flexDirection: "row", alignItems: "center", gap: 8, borderWidth: 1, borderColor: colors.line, borderRadius: 17, paddingLeft: 13, backgroundColor: "#fafcfb" };
styles.chatInput = { flex: 1, minHeight: 47, color: colors.ink, fontSize: 15, paddingVertical: 8 };
styles.chatSend = { width: 37, height: 37, borderRadius: 19, alignItems: "center", justifyContent: "center", marginRight: 5, backgroundColor: colors.blue };
styles.chatSendDisabled = { backgroundColor: "#b9c8c5" };
styles.chatSendText = { color: "white", fontSize: 22, fontWeight: "700", lineHeight: 24 };
styles.microphoneButton = { alignSelf: "center", minWidth: 180, flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 8, paddingHorizontal: 18, paddingVertical: 12, borderRadius: 26, backgroundColor: colors.blue };
styles.microphoneButtonListening = { backgroundColor: colors.red };
styles.microphoneButtonSpeaking = { backgroundColor: colors.success };
styles.microphoneIcon = { color: "white", fontSize: 18 };
styles.microphoneText = { color: "white", fontSize: 12, fontWeight: "800" };
styles.addressPicker = { gap: 4 };
styles.addressSuggestion = { paddingHorizontal: 12, paddingVertical: 10, borderWidth: 1, borderColor: colors.line, borderRadius: 9, backgroundColor: "white" };
styles.addressSuggestionText = { color: colors.ink, fontSize: 12, lineHeight: 17 };
styles.googleAttribution = { color: colors.muted, fontSize: 10, fontWeight: "700", textAlign: "right", marginTop: 2 };
styles.phoneCodeRow = { gap: 7, paddingRight: 12 };
styles.phoneCode = { paddingHorizontal: 10, paddingVertical: 8, borderRadius: 15, backgroundColor: "#edf2f3" };
styles.phoneCodeActive = { backgroundColor: colors.blue };
styles.phoneCodeText = { color: colors.muted, fontSize: 11, fontWeight: "800" };
styles.phoneCodeTextActive = { color: "white" };
styles.phoneInputRow = { flexDirection: "row", alignItems: "center", borderWidth: 1, borderColor: colors.line, borderRadius: 10, backgroundColor: "white", minHeight: 48 };
styles.phonePrefix = { color: colors.blue, fontSize: 14, fontWeight: "800", paddingHorizontal: 12, borderRightWidth: 1, borderColor: colors.line };
styles.phoneInput = { flex: 1, color: colors.ink, fontSize: 14, paddingHorizontal: 12, minHeight: 46 };
styles.authFieldLabel = { color: colors.ink, fontSize: 12, fontWeight: "800", marginTop: 4 };
