"""Accept transient Android PCM audio for the microphone prototype."""

import json
import logging
import time

from fastapi import WebSocket
from starlette.websockets import WebSocketDisconnect

from mic.single_note_detector import SingleNoteDetector


logger = logging.getLogger("uvicorn.error")


async def stream_microphone_audio(websocket: WebSocket) -> None:
    """Analyze live PCM and return note events without saving audio."""
    await websocket.accept()

    try:
        setup_text = await websocket.receive_text()
        try:
            setup = json.loads(setup_text)
        except json.JSONDecodeError:
            setup = None

        if (
            not isinstance(setup, dict)
            or setup.get("type") != "start"
            or setup.get("encoding") != "pcm16le"
            or setup.get("channels") != 1
            or type(setup.get("sampleRate")) is not int
            or not 8000 <= setup["sampleRate"] <= 96000
            or type(setup.get("sensitivity", 100)) is not int
            or not 60 <= setup.get("sensitivity", 100) <= 100
        ):
            await websocket.send_json({
                "type": "error",
                "message": "Expected mono PCM16 audio, sample rate, and sensitivity.",
            })
            await websocket.close(code=1003)
            return

        await websocket.send_json({
            "type": "ready",
            "encoding": "pcm16le",
            "channels": 1,
            "sampleRate": setup["sampleRate"],
            "sensitivity": setup.get("sensitivity", 100),
        })
        logger.info("Microphone stream connected at %s Hz", setup["sampleRate"])
        detector = SingleNoteDetector(
            setup["sampleRate"], sensitivity=setup.get("sensitivity", 100)
        )
        await websocket.send_json({"type": "calibration", "state": "calibrating"})

        bytes_received = 0
        chunks_received = 0
        last_acknowledgement = 0.0

        while True:
            message = await websocket.receive()
            if message["type"] == "websocket.disconnect":
                return

            audio = message.get("bytes")
            if audio is None:
                await websocket.send_json({
                    "type": "error",
                    "message": "Send audio as binary PCM16 messages.",
                })
                await websocket.close(code=1003)
                return
            if not audio or len(audio) % 2 != 0:
                continue

            bytes_received += len(audio)
            chunks_received += 1
            if chunks_received == 1:
                logger.info("Microphone audio arriving at Python")
            now = time.monotonic()
            if chunks_received == 1 or now - last_acknowledgement >= 0.5:
                await websocket.send_json({
                    "type": "audio_received",
                    "bytesReceived": bytes_received,
                    "chunksReceived": chunks_received,
                })
                last_acknowledgement = now

            for result in detector.feed(audio):
                await websocket.send_json(result)
    except WebSocketDisconnect:
        return
    finally:
        logger.info("Microphone stream closed")
