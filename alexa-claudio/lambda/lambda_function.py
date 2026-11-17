import logging

import anthropic
from ask_sdk_core.skill_builder import SkillBuilder
from ask_sdk_core.utils import is_intent_name, is_request_type

API_KEY = "PEGA_ACA_TU_API_KEY"
MODELO = "claude-haiku-5-5"
MAX_TURNOS = 10

PERSONALIDAD = """Sos Claude hablando por un altavoz Alexa en la casa de Abel.
Hablas en español argentino, directo y con humor.
Respondes en 2 o 3 oraciones como mucho, porque se escucha en voz alta.
Nada de listas, simbolos, markdown ni emojis: solo texto para ser leido.
Si no sabes algo, lo decis sin vueltas."""

log = logging.getLogger(__name__)
log.setLevel(logging.INFO)
cliente = anthropic.Anthropic(api_key=API_KEY, timeout=6.5, max_retries=0)


def preguntar_a_claude(historial):
    try:
        r = cliente.messages.create(
            model=MODELO,
            max_tokens=250,
            system=PERSONALIDAD,
            messages=historial,
            # Haiku 5.5 piensa por defecto: eso suma demora (Alexa corta a ~8 s)
            # y puede gastar los 250 tokens antes de responder. Para voz, sin thinking.
            thinking={"type": "disabled"},
        )
        if r.stop_reason == "refusal":
            return "De eso prefiero no hablar, perri."
        # No asumir que content[0] es texto: juntar solo los bloques de texto.
        texto = "".join(b.text for b in r.content if b.type == "text").strip()
        return texto or None
    except Exception as e:
        log.error("Fallo la API: %s", e)
        return None


def abrir(h):
    h.attributes_manager.session_attributes["historial"] = []
    return h.response_builder.speak("Acá estoy, perri. ¿Qué necesitás?").ask("Te escucho.").response


def charlar(h):
    slots = h.request_envelope.request.intent.slots or {}
    texto = slots["consulta"].value if "consulta" in slots else None
    if not texto:
        return no_entendi(h)
    attrs = h.attributes_manager.session_attributes
    historial = attrs.get("historial", [])
    historial.append({"role": "user", "content": texto})
    respuesta = preguntar_a_claude(historial)
    if respuesta is None:
        historial.pop()
        return h.response_builder.speak("Me colgué pensando. Probá de nuevo.").ask("Te escucho.").response
    historial.append({"role": "assistant", "content": respuesta})
    attrs["historial"] = historial[-MAX_TURNOS * 2:]
    return h.response_builder.speak(respuesta).ask("¿Algo más?").response


def no_entendi(h):
    return h.response_builder.speak("No te cacé. Arrancá la frase con che, o con decime.").ask("Te escucho.").response


def chau(h):
    return h.response_builder.speak("Nos vemos, perri.").response


def fin_sesion(h):
    return h.response_builder.response


def error(h, exception):
    log.error(exception, exc_info=True)
    return h.response_builder.speak("Algo se rompió. Probá otra vez.").ask("Te escucho.").response


sb = SkillBuilder()
sb.request_handler(can_handle_func=is_request_type("LaunchRequest"))(abrir)
sb.request_handler(can_handle_func=is_intent_name("CharlaIntent"))(charlar)
sb.request_handler(can_handle_func=lambda h: is_intent_name("AMAZON.StopIntent")(h) or is_intent_name("AMAZON.CancelIntent")(h))(chau)
sb.request_handler(can_handle_func=is_intent_name("AMAZON.FallbackIntent"))(no_entendi)
sb.request_handler(can_handle_func=is_intent_name("AMAZON.HelpIntent"))(no_entendi)
sb.request_handler(can_handle_func=is_request_type("SessionEndedRequest"))(fin_sesion)
sb.exception_handler(can_handle_func=lambda h, e: True)(error)

lambda_handler = sb.lambda_handler()
