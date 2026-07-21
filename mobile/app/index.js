import { useEffect, useMemo, useState } from "react";
import { ActivityIndicator, Alert, Modal, SafeAreaView, ScrollView, StyleSheet, Switch, Text, TextInput, TouchableOpacity, View } from "react-native";
import { StatusBar } from "expo-status-bar";
import { clearTokens, getSession, requestCode, saveSession, signIn, signUp } from "../services/auth";

const colors = {
  blue: "#0b4f6c", sky: "#01baef", red: "#b80c09", canvas: "#fbfbff", ink: "#040f16", muted: "#61727a", line: "#d9e4e7", success: "#177b59"
};

const initialTasks = [
  { id: "medicine", icon: "◷", title: "Take Amlodipine", detail: "1 tablet · with breakfast", time: "9:00 AM", kind: "medicine", done: false },
  { id: "visit", icon: "♡", title: "Physiotherapy visit", detail: "Ravi is expected", time: "10:00 AM", kind: "visit", done: false },
  { id: "test", icon: "⌁", title: "Blood test", detail: "Home collection", time: "2:00 PM", kind: "appointment", done: false },
  { id: "walk", icon: "⌂", title: "Evening walk", detail: "15 minutes", time: "6:00 PM", kind: "reminder", done: false }
];

const helpOptions = [
  ["✚", "Medical support", "Doctor, nurse, or a health check"],
  ["⌂", "Household help", "Cleaning, cooking, or errands"],
  ["▧", "Shopping", "Groceries and essentials"],
  ["◌", "Transport", "Rides to appointments"],
  ["♡", "Companion visit", "Someone to spend time with"],
  ["▣", "Digital assistance", "Help with phones or devices"]
];

const contacts = [
  { name: "Anita Sharma", role: "Daughter", phone: "+91 98765 43211", access: "Appointments, visits & emergencies" },
  { name: "Dr. Mehta", role: "Doctor", phone: "+91 98765 43212", access: "Health documents" }
];

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

function AuthenticationScreen({ onAuthenticated }) {
  const [mode, setMode] = useState("signIn");
  const [step, setStep] = useState("details");
  const [identifier, setIdentifier] = useState("");
  const [code, setCode] = useState("");
  const [fullName, setFullName] = useState("");
  const [country, setCountry] = useState("");
  const [memberName, setMemberName] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const sendCode = async () => {
    setBusy(true); setError("");
    try { await requestCode(identifier); setStep("code"); } catch (requestError) { setError(requestError.message); } finally { setBusy(false); }
  };
  const verify = async () => {
    setBusy(true); setError("");
    try {
      const result = mode === "signIn" ? await signIn(identifier, code) : await signUp({ identifier, code, user: { full_name: fullName, country }, member: { full_name: memberName, preferred_language: "English", relationship_to_user: "self", country } });
      await saveSession(result.user, result.tokens);
      onAuthenticated(result.user);
    } catch (requestError) { setError(requestError.message); } finally { setBusy(false); }
  };
  const switchMode = (nextMode) => { setMode(nextMode); setStep("details"); setCode(""); setError(""); };

  return <SafeAreaView style={styles.safe}><StatusBar style="dark" /><ScrollView contentContainerStyle={styles.authScreen} keyboardShouldPersistTaps="handled">
    <Text style={styles.authBrand}>♡</Text><Text style={styles.authLabel}>GOLDENLY</Text>
    <Text style={styles.authTitle}>{mode === "signIn" ? "Welcome back" : "Create your account"}</Text>
    <Text style={styles.authIntro}>{step === "code" ? `Enter the code sent to ${identifier}.` : "Use your email address or phone number to securely continue."}</Text>
    <View style={styles.modeRow}><TouchableOpacity onPress={() => switchMode("signIn")} style={[styles.modeButton, mode === "signIn" && styles.modeButtonActive]}><Text style={[styles.modeText, mode === "signIn" && styles.modeTextActive]}>Sign in</Text></TouchableOpacity><TouchableOpacity onPress={() => switchMode("signUp")} style={[styles.modeButton, mode === "signUp" && styles.modeButtonActive]}><Text style={[styles.modeText, mode === "signUp" && styles.modeTextActive]}>Sign up</Text></TouchableOpacity></View>
    {step === "details" ? <View style={styles.authForm}>{mode === "signUp" && <><TextInput value={fullName} onChangeText={setFullName} style={styles.authInput} placeholder="Your name" placeholderTextColor={colors.muted} /><TextInput value={country} onChangeText={setCountry} style={styles.authInput} placeholder="Country" placeholderTextColor={colors.muted} /><TextInput value={memberName} onChangeText={setMemberName} style={styles.authInput} placeholder="First member’s name" placeholderTextColor={colors.muted} /></>}<TextInput value={identifier} onChangeText={setIdentifier} style={styles.authInput} placeholder="Email or +phone number" placeholderTextColor={colors.muted} autoCapitalize="none" autoCorrect={false} />{error ? <Text style={styles.authError}>{error}</Text> : null}<ActionButton onPress={sendCode}>{busy ? "Sending…" : "Send verification code"}</ActionButton></View> : <View style={styles.authForm}><TextInput value={code} onChangeText={setCode} style={styles.authInput} placeholder="Verification code" placeholderTextColor={colors.muted} keyboardType="number-pad" autoComplete="one-time-code" />{error ? <Text style={styles.authError}>{error}</Text> : null}<ActionButton onPress={verify}>{busy ? "Verifying…" : mode === "signIn" ? "Verify and sign in" : "Verify and create account"}</ActionButton><TouchableOpacity onPress={() => setStep("details")}><Text style={styles.changeIdentifier}>Use a different email or phone number</Text></TouchableOpacity></View>}
    <Text style={styles.authSafety}>Goldenly uses one-time codes to protect your account. We do not ask for a password in the mobile app.</Text>
  </ScrollView></SafeAreaView>;
}

export default function Home() {
  const [user, setUser] = useState(null);
  const [authReady, setAuthReady] = useState(false);
  const [tab, setTab] = useState("Today");
  const [tasks, setTasks] = useState(initialTasks);
  const [selectedHelp, setSelectedHelp] = useState(null);
  const [requestSaved, setRequestSaved] = useState(false);
  const [assistantOpen, setAssistantOpen] = useState(false);
  const [message, setMessage] = useState("");
  const [assistantReply, setAssistantReply] = useState("");
  const [sosOpen, setSosOpen] = useState(false);
  const [shareLocation, setShareLocation] = useState(false);
  const [careSection, setCareSection] = useState("Medicines");

  useEffect(() => { getSession().then(setUser).finally(() => setAuthReady(true)); }, []);
  if (!authReady) return <SafeAreaView style={styles.loading}><ActivityIndicator color={colors.blue} size="large" /></SafeAreaView>;
  if (!user) return <AuthenticationScreen onAuthenticated={setUser} />;

  const date = useMemo(() => new Intl.DateTimeFormat(undefined, { weekday: "long", month: "long", day: "numeric" }).format(new Date()), []);
  const pendingCount = tasks.filter((task) => !task.done).length;

  const completeTask = (id) => setTasks(tasks.map((task) => task.id === id ? { ...task, done: true } : task));
  const sendMessage = () => {
    const normalized = message.trim().toLowerCase();
    if (!normalized) return;
    if (normalized.includes("medicine") || normalized.includes("reminder")) setAssistantReply("I can help create a reminder. Please confirm the time before I save it.");
    else if (normalized.includes("doctor") || normalized.includes("pain") || normalized.includes("medical")) setAssistantReply("I can help request medical support, but I cannot diagnose or recommend treatment. Would you like to choose Medical support?");
    else setAssistantReply("I can help with your schedule, reminders, services, and trusted contacts. What would you like to do?");
  };
  const confirmHelp = () => { setRequestSaved(true); setSelectedHelp(null); };
  const confirmSos = () => {
    setSosOpen(false);
    Alert.alert("Emergency plan ready", `Your emergency contacts will be notified after you confirm. Location sharing is ${shareLocation ? "included" : "off"}.`);
  };

  const renderToday = () => <>
    <Text style={styles.pageTitle}>Today</Text><Text style={styles.date}>{date}</Text>
    <View style={styles.wellbeing}><Text style={styles.wellbeingIcon}>♡</Text><View style={styles.flex}><Text style={styles.wellbeingTitle}>You’re doing well today</Text><Text style={styles.detail}>You have {pendingCount} things left in your plan.</Text></View></View>
    <Text style={styles.sectionTitle}>Your plan</Text>
    <View style={styles.cards}>{tasks.map((task) => <View key={task.id} style={styles.task}>
      <Text style={styles.taskIcon}>{task.icon}</Text><View style={styles.flex}><Text style={[styles.cardTitle, task.done && styles.completedText]}>{task.title}</Text><Text style={styles.detail}>{task.detail}</Text><Text style={styles.time}>{task.time}</Text></View>
      {task.done ? <View style={styles.donePill}><Text style={styles.doneText}>Done ✓</Text></View> : <ActionButton onPress={() => task.kind === "medicine" || task.kind === "reminder" ? completeTask(task.id) : Alert.alert(task.title, "This appointment is on your care plan.")}>{task.kind === "medicine" ? "Take" : task.kind === "reminder" ? "Done" : "View"}</ActionButton>}
    </View>)}</View>
    <TouchableOpacity accessibilityRole="button" onPress={() => setAssistantOpen(true)} style={styles.voice}><Text style={styles.voiceSparkle}>✦</Text><View style={styles.flex}><Text style={styles.voiceText}>Talk to Goldenly</Text><Text style={styles.voiceHint}>Speak or type in your preferred language</Text></View><Text style={styles.microphone}>◉</Text></TouchableOpacity>
  </>;

  const renderHelp = () => <>
    <Text style={styles.pageTitle}>Get help</Text><Text style={styles.date}>Choose what you need. You will confirm before we send a request.</Text>
    {requestSaved && <View style={styles.confirmation}><Text style={styles.confirmationTitle}>Request saved</Text><Text style={styles.detail}>We’ll wait for your confirmation before arranging a provider.</Text></View>}
    <View style={styles.cards}>{helpOptions.map(([icon, title, detail]) => <TouchableOpacity key={title} accessibilityRole="button" onPress={() => { setRequestSaved(false); setSelectedHelp({ title, detail }); }} style={styles.helpCard}><Text style={styles.helpIcon}>{icon}</Text><View style={styles.flex}><Text style={styles.cardTitle}>{title}</Text><Text style={styles.detail}>{detail}</Text></View><Text style={styles.chevron}>›</Text></TouchableOpacity>)}</View>
  </>;

  const renderCare = () => <>
    <Text style={styles.pageTitle}>My care</Text><Text style={styles.date}>Your health and care information</Text>
    <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.segmentRow}>{["Medicines", "Appointments", "Documents", "Services"].map((item) => <TouchableOpacity key={item} onPress={() => setCareSection(item)} style={[styles.segment, careSection === item && styles.segmentActive]}><Text style={[styles.segmentText, careSection === item && styles.segmentTextActive]}>{item}</Text></TouchableOpacity>)}</ScrollView>
    {careSection === "Medicines" && <View style={styles.infoCard}><Text style={styles.cardTitle}>Amlodipine</Text><Text style={styles.detail}>1 tablet · every day at 9:00 AM</Text><Text style={styles.safeNote}>Check with your clinician before changing medication.</Text></View>}
    {careSection === "Appointments" && <View style={styles.infoCard}><Text style={styles.cardTitle}>Physiotherapy visit</Text><Text style={styles.detail}>Today · 10:00 AM · Ravi Kumar</Text></View>}
    {careSection === "Documents" && <View style={styles.infoCard}><Text style={styles.cardTitle}>Medical documents</Text><Text style={styles.detail}>No new documents to review.</Text><Text style={styles.safeNote}>Document summaries are informational, not medical advice.</Text></View>}
    {careSection === "Services" && <View style={styles.infoCard}><Text style={styles.cardTitle}>Previous services</Text><Text style={styles.detail}>No completed services yet.</Text></View>}
  </>;

  const renderCircle = () => <>
    <Text style={styles.pageTitle}>My circle</Text><Text style={styles.date}>People you trust to support your care</Text>
    <View style={styles.cards}>{contacts.map((contact) => <View key={contact.name} style={styles.contactCard}><View style={styles.contactAvatar}><Text style={styles.contactAvatarText}>{contact.name[0]}</Text></View><View style={styles.flex}><Text style={styles.cardTitle}>{contact.name}</Text><Text style={styles.detail}>{contact.role}</Text><Text style={styles.access}>{contact.access}</Text></View><ActionButton secondary onPress={() => Alert.alert("Contact", `${contact.name}\n${contact.phone}`)}>Call</ActionButton></View>)}</View>
    <View style={styles.permissionCard}><Text style={styles.cardTitle}>Your privacy matters</Text><Text style={styles.detail}>Only share care information with people you choose. Permission controls will be available when your account is connected.</Text></View>
  </>;

  const body = tab === "Today" ? renderToday() : tab === "Help" ? renderHelp() : tab === "My Care" ? renderCare() : renderCircle();
  return <SafeAreaView style={styles.safe}><StatusBar style="dark" />
    <ScrollView contentContainerStyle={styles.screen}>{<View style={styles.top}><View><Text style={styles.brand}>♡</Text><Text style={styles.label}>GOLDENLY</Text></View><TouchableOpacity onPress={async () => { await clearTokens(); setUser(null); }} style={styles.memberBadge}><Text style={styles.memberName}>{user.full_name}</Text><Text style={styles.memberSub}>Sign out</Text></TouchableOpacity></View>}{body}</ScrollView>
    <View style={styles.nav}>{[["Today", "⌂"], ["Help", "✦"], ["SOS", "✚"], ["My Care", "♡"], ["My Circle", "♧"]].map(([name, icon]) => <TouchableOpacity key={name} accessibilityRole="button" accessibilityLabel={name} onPress={() => name === "SOS" ? setSosOpen(true) : setTab(name)} style={styles.navItem}><Text style={[styles.navIcon, name === "SOS" && styles.sosIcon]}>{icon}</Text><Text style={[styles.navText, tab === name && styles.activeText, name === "SOS" && styles.sosText]}>{name}</Text></TouchableOpacity>)}</View>
    <ModalSheet visible={Boolean(selectedHelp)} title={selectedHelp?.title || "Request help"} onClose={() => setSelectedHelp(null)}><Text style={styles.sheetText}>{selectedHelp?.detail}</Text><Text style={styles.safeNote}>Goldenly will not book or dispatch anyone until you confirm.</Text><ActionButton onPress={confirmHelp}>Confirm request</ActionButton><ActionButton secondary onPress={() => setSelectedHelp(null)}>Not now</ActionButton></ModalSheet>
    <ModalSheet visible={assistantOpen} title="Talk to Goldenly" onClose={() => setAssistantOpen(false)}><Text style={styles.sheetText}>Tell me what you need. I can help with routines, reminders, and support requests.</Text><TextInput value={message} onChangeText={setMessage} placeholder="Type a message…" placeholderTextColor={colors.muted} style={styles.input} multiline accessibilityLabel="Message Goldenly" />{assistantReply ? <View style={styles.assistantReply}><Text style={styles.detail}>{assistantReply}</Text></View> : null}<ActionButton onPress={sendMessage}>Ask Goldenly</ActionButton><Text style={styles.safeNote}>Goldenly does not provide medical diagnoses or treatment advice.</Text></ModalSheet>
    <ModalSheet visible={sosOpen} title="Emergency SOS" onClose={() => setSosOpen(false)}><Text style={styles.sheetText}>This can notify your selected emergency contacts and begin Goldenly’s emergency workflow.</Text><View style={styles.locationRow}><View style={styles.flex}><Text style={styles.cardTitle}>Share my location</Text><Text style={styles.detail}>Only if you consent</Text></View><Switch value={shareLocation} onValueChange={setShareLocation} trackColor={{ false: colors.line, true: colors.sky }} /></View><Text style={styles.safeNote}>For immediate danger, contact local emergency services first.</Text><ActionButton onPress={confirmSos}>Continue to confirmation</ActionButton><ActionButton secondary onPress={() => setSosOpen(false)}>Cancel</ActionButton></ModalSheet>
  </SafeAreaView>;
}

const styles = StyleSheet.create({
  loading: { flex: 1, alignItems: "center", justifyContent: "center", backgroundColor: colors.canvas }, authScreen: { flexGrow: 1, justifyContent: "center", padding: 28 }, authBrand: { color: colors.blue, textAlign: "center", fontSize: 43 }, authLabel: { color: colors.blue, textAlign: "center", fontSize: 11, fontWeight: "800", letterSpacing: 2, marginBottom: 34 }, authTitle: { color: colors.ink, fontSize: 29, fontWeight: "800" }, authIntro: { color: colors.muted, fontSize: 14, lineHeight: 20, marginTop: 8, marginBottom: 20 }, modeRow: { flexDirection: "row", gap: 8, marginBottom: 18 }, modeButton: { flex: 1, alignItems: "center", paddingVertical: 10, borderRadius: 9, backgroundColor: "#edf2f3" }, modeButtonActive: { backgroundColor: colors.blue }, modeText: { color: colors.muted, fontSize: 13, fontWeight: "800" }, modeTextActive: { color: "white" }, authForm: { gap: 10 }, authInput: { minHeight: 48, borderWidth: 1, borderColor: colors.line, borderRadius: 10, paddingHorizontal: 12, color: colors.ink, fontSize: 14, backgroundColor: "white" }, authError: { color: colors.red, fontSize: 12, lineHeight: 17 }, changeIdentifier: { color: colors.blue, textAlign: "center", fontSize: 12, fontWeight: "800", padding: 10 }, authSafety: { color: colors.muted, fontSize: 11, lineHeight: 16, textAlign: "center", marginTop: 24 },
  safe: { flex: 1, backgroundColor: colors.canvas }, screen: { padding: 22, paddingBottom: 108 }, flex: { flex: 1 }, top: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 27 }, brand: { color: colors.blue, fontSize: 32, lineHeight: 32 }, label: { color: colors.blue, fontWeight: "800", fontSize: 10, letterSpacing: 1.8, marginTop: 3 }, memberBadge: { paddingHorizontal: 11, paddingVertical: 7, borderRadius: 12, backgroundColor: "#e9f3f7" }, memberName: { color: colors.blue, fontSize: 13, fontWeight: "800" }, memberSub: { color: colors.muted, fontSize: 10, marginTop: 1 }, pageTitle: { color: colors.ink, fontSize: 31, fontWeight: "800", letterSpacing: -1 }, date: { color: colors.muted, fontSize: 14, marginTop: 5, marginBottom: 22, lineHeight: 20 }, sectionTitle: { color: colors.ink, fontWeight: "800", fontSize: 17, marginBottom: 10 }, wellbeing: { backgroundColor: "#e9f5f7", padding: 16, borderRadius: 16, flexDirection: "row", gap: 12, alignItems: "center", marginBottom: 22 }, wellbeingIcon: { color: colors.blue, fontSize: 29 }, wellbeingTitle: { color: colors.blue, fontSize: 16, fontWeight: "800" }, cards: { gap: 12 }, task: { backgroundColor: "white", borderWidth: 1, borderColor: colors.line, borderRadius: 15, padding: 15, flexDirection: "row", alignItems: "center", gap: 11 }, taskIcon: { color: colors.blue, fontSize: 22 }, cardTitle: { color: colors.ink, fontWeight: "800", fontSize: 15 }, completedText: { color: colors.muted, textDecorationLine: "line-through" }, detail: { color: colors.muted, fontSize: 12, marginTop: 3, lineHeight: 17 }, time: { color: colors.blue, fontSize: 11, fontWeight: "800", marginTop: 8 }, actionButton: { backgroundColor: colors.blue, alignItems: "center", justifyContent: "center", paddingHorizontal: 13, paddingVertical: 10, borderRadius: 9, minHeight: 40 }, actionButtonText: { color: "white", fontSize: 12, fontWeight: "800" }, secondaryButton: { backgroundColor: "#e9f3f7" }, secondaryButtonText: { color: colors.blue }, donePill: { backgroundColor: "#e5f5ed", paddingHorizontal: 9, paddingVertical: 7, borderRadius: 7 }, doneText: { color: colors.success, fontSize: 11, fontWeight: "800" }, voice: { marginTop: 24, backgroundColor: colors.blue, borderRadius: 16, padding: 17, flexDirection: "row", alignItems: "center", gap: 10 }, voiceSparkle: { color: colors.sky, fontSize: 22 }, voiceText: { color: "white", fontWeight: "800", fontSize: 16 }, voiceHint: { color: "#c5e2eb", fontSize: 11, marginTop: 3 }, microphone: { color: "white", fontSize: 22 }, confirmation: { padding: 14, borderRadius: 13, backgroundColor: "#e5f5ed", marginBottom: 15 }, confirmationTitle: { color: colors.success, fontSize: 14, fontWeight: "800" }, helpCard: { padding: 17, backgroundColor: "white", borderRadius: 15, borderWidth: 1, borderColor: colors.line, flexDirection: "row", alignItems: "center", gap: 14, minHeight: 78 }, helpIcon: { color: colors.blue, fontSize: 23 }, chevron: { color: colors.blue, fontSize: 29 }, segmentRow: { gap: 8, paddingBottom: 18 }, segment: { paddingHorizontal: 13, paddingVertical: 9, borderRadius: 20, backgroundColor: "#edf2f3" }, segmentActive: { backgroundColor: colors.blue }, segmentText: { color: colors.muted, fontSize: 12, fontWeight: "800" }, segmentTextActive: { color: "white" }, infoCard: { padding: 18, borderRadius: 16, backgroundColor: "white", borderWidth: 1, borderColor: colors.line }, safeNote: { color: colors.muted, fontSize: 11, lineHeight: 16, marginTop: 13 }, contactCard: { padding: 15, borderRadius: 15, backgroundColor: "white", borderWidth: 1, borderColor: colors.line, flexDirection: "row", alignItems: "center", gap: 11 }, contactAvatar: { width: 38, height: 38, borderRadius: 19, alignItems: "center", justifyContent: "center", backgroundColor: colors.sky }, contactAvatarText: { color: "white", fontWeight: "800" }, access: { color: colors.blue, fontSize: 10, fontWeight: "700", marginTop: 6 }, permissionCard: { marginTop: 18, padding: 16, borderRadius: 15, backgroundColor: "#e9f3f7" }, nav: { position: "absolute", bottom: 0, left: 0, right: 0, paddingVertical: 9, paddingHorizontal: 4, borderTopWidth: 1, borderColor: colors.line, backgroundColor: "white", flexDirection: "row", justifyContent: "space-around" }, navItem: { alignItems: "center", flex: 1, minHeight: 43 }, navIcon: { fontSize: 19, color: colors.blue }, navText: { fontSize: 9, color: colors.muted, marginTop: 2, textAlign: "center" }, activeText: { color: colors.blue, fontWeight: "800" }, sosIcon: { color: colors.red }, sosText: { color: colors.red, fontWeight: "800" }, modalBackdrop: { flex: 1, justifyContent: "flex-end", backgroundColor: "rgba(4,15,22,.38)" }, sheet: { backgroundColor: "white", borderTopLeftRadius: 25, borderTopRightRadius: 25, padding: 23, gap: 13 }, sheetHandle: { alignSelf: "center", width: 40, height: 4, borderRadius: 3, backgroundColor: colors.line, marginBottom: 4 }, sheetHeading: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" }, sheetTitle: { color: colors.ink, fontSize: 22, fontWeight: "800" }, close: { color: colors.muted, fontSize: 30, lineHeight: 30 }, sheetText: { color: colors.ink, fontSize: 14, lineHeight: 20 }, input: { minHeight: 88, borderWidth: 1, borderColor: colors.line, borderRadius: 11, padding: 12, color: colors.ink, fontSize: 14, textAlignVertical: "top" }, assistantReply: { padding: 12, borderRadius: 10, backgroundColor: "#e9f3f7" }, locationRow: { flexDirection: "row", alignItems: "center", gap: 12, paddingVertical: 7 }
});
