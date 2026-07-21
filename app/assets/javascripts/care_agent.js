const careAgent = () => {
  document.querySelectorAll("[data-care-agent]").forEach((agent) => {
    if (agent.dataset.ready) return;
    agent.dataset.ready = "true";

    const dialog = agent.querySelector("dialog");
    const input = agent.querySelector("[data-agent-input]");
    const reply = agent.querySelector("[data-agent-reply]");
    const proposal = agent.querySelector("[data-agent-proposal]");
    const submit = agent.querySelector("[data-agent-submit]");
    const microphone = agent.querySelector("[data-agent-microphone]");
    const language = agent.querySelector("[data-agent-language]");
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content;
    let pendingProposal = null;

    const show = (element, text) => {
      element.textContent = text;
      element.hidden = false;
    };

    const request = async (url, body) => {
      const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json", Accept: "application/json", "X-CSRF-Token": csrfToken },
        body: JSON.stringify(body)
      });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error || "Goldenly could not complete that request.");
      return payload;
    };

    agent.querySelectorAll("[data-agent-open]").forEach((button) => button.addEventListener("click", () => dialog.showModal()));
    agent.querySelectorAll("[data-agent-close]").forEach((button) => button.addEventListener("click", () => dialog.close()));

    submit.addEventListener("click", async () => {
      const message = input.value.trim();
      if (!message) return show(reply, "Please tell Goldenly what you need.");
      submit.disabled = true;
      show(reply, "Goldenly is checking the member’s care record…");
      proposal.hidden = true;
      try {
        const payload = await request(agent.dataset.messageUrl, { message, language: language.value });
        show(reply, payload.reply);
        pendingProposal = payload.proposal;
        if (pendingProposal) {
          proposal.querySelector("[data-proposal-title]").textContent = pendingProposal.title;
          proposal.querySelector("[data-proposal-summary]").textContent = pendingProposal.summary;
          proposal.querySelector("[data-proposal-confirmation]").textContent = pendingProposal.confirmation;
          proposal.hidden = false;
        }
      } catch (error) {
        show(reply, error.message);
      } finally {
        submit.disabled = false;
      }
    });

    agent.querySelector("[data-agent-confirm]").addEventListener("click", async () => {
      if (!pendingProposal) return;
      try {
        const shareLocation = agent.querySelector("[data-agent-share-location]").checked;
        const payload = await request(agent.dataset.confirmUrl, { share_location: shareLocation });
        show(reply, payload.message);
        proposal.hidden = true;
        pendingProposal = null;
        if (payload.emergency_call_url) {
          const call = document.createElement("a");
          call.href = payload.emergency_call_url;
          call.className = "agent-emergency-call";
          call.textContent = `Call emergency services now`;
          reply.after(call);
        }
      } catch (error) {
        show(reply, error.message);
      }
    });

    const Recognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!Recognition) {
      microphone.hidden = true;
      return;
    }

    microphone.addEventListener("click", () => {
      const recognition = new Recognition();
      recognition.lang = language.value === "Telugu" ? "te-IN" : "en-IN";
      recognition.interimResults = false;
      recognition.maxAlternatives = 1;
      microphone.disabled = true;
      microphone.textContent = "Listening…";
      recognition.onresult = (event) => { input.value = event.results[0][0].transcript; };
      recognition.onerror = () => show(reply, "I could not hear that. Please try again or type your request.");
      recognition.onend = () => { microphone.disabled = false; microphone.textContent = "Speak"; };
      recognition.start();
    });
  });
};

document.addEventListener("DOMContentLoaded", careAgent);
document.addEventListener("turbo:load", careAgent);
