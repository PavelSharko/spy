# Spec: Telegram Gemini Chatbot

**Slug:** `telegram-gemini-chatbot`  
**Date:** `2026-03-19`  
**Status:** Draft

## Summary

This automation receives text messages from users via a Telegram Bot, routes their text to Google Gemini (using the 2.5 Pro model) to generate an intelligent response, and sends that answer straight back to the original user in Telegram. It replaces manual responses and provides an automated interactive chat flow.

## Node Pipeline

| # | Node Name | Type | Purpose | Key Parameters |
|---|-----------|------|---------|----------------|
| 1 | Telegram Trigger | `n8n-nodes-base.telegramTrigger` | Listens for new incoming chat messages. | `updates: ["message"]`<br>`credential: "Telegram boty"` |
| 2 | Google Gemini | `@n8n/n8n-nodes-langchain.googleGemini` | Takes the incoming text and generates an AI reply. | `resource: "text"`<br>`model: "gemini-2.5-pro"`<br>`prompt: ={{$json.message.text}}`<br>`credential: "share-key-gemini"` |
| 3 | Telegram Action | `n8n-nodes-base.telegram` | Sends the AI-generated text back to the Telegram chat. | `resource: "message"`<br>`operation: "sendMessage"`<br>`chatId: ={{ $('Telegram Trigger').item.json.message.chat.id }}`<br>`text: ={{ $json.text }}` |

## Data Flow

1. **Incoming (Telegram Trigger):** Emits payload holding `$json.message.text` and `$json.message.chat.id`.
2. **AI Processing (Google Gemini):** Takes the text payload as an input prompt and uses the `"share-key-gemini"` credential to securely query the `"gemini-2.5-pro"` model. The response comes back as `$json.text`.
3. **Outgoing (Telegram Action):** Combines the AI's generated text `$json.text` with the original chat identification `=$('Telegram Trigger').item.json.message.chat.id` to route the message back safely.

## Credentials Required

- `telegramApi` – Required for both the Telegram Trigger and Telegram Action nodes. The user specifies selecting **"Telegram boty"**. 
- `googleGeminiApi` (or `googleApi`) – Required for the Google Gemini node. The user specifies selecting **"share-key-gemini"**.

## Error Handling

- **API Rate Limiting / Errors:** If Gemini takes too long or throws a rate limit error, the Gemini node should ideally have `continueOnFail: true` or be wired into an error branch.
- **Fail-safe Action:** If the Gemini node fails, a fallback Telegram Action node should notify the user: *"Извините, ИИ сейчас перегружен, попробуйте чуть позже."* 
