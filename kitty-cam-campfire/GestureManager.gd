extends Node

signal gesture_up
signal gesture_left
signal gesture_right
signal gesture_none

var current_gesture = "None"

func _ready():
	print("GestureManager _ready() called")
	
	JavaScriptBridge.eval("""
		(function() {
			if (window.godotGestureInit) return;
			window.godotGestureInit = true;
			window.godotCurrentGesture = "None";

			window.getGesture = function() {
				return window.godotCurrentGesture || "None";
			};

			function loadScript(src, onload, onerror) {
				var s = document.createElement("script");
				s.src = src;
				s.onload = onload;
				s.onerror = onerror || function() { console.error("❌ Failed to load: " + src); };
				document.head.appendChild(s);
			}

			// Step 1: Load TF 1.3.1
			loadScript("https://cdn.jsdelivr.net/npm/@tensorflow/tfjs@1.3.1/dist/tf.min.js", function() {
				console.log("✅ TensorFlow.js 1.3.1 loaded");

				// Step 2: Load PoseNet
				loadScript("https://cdn.jsdelivr.net/npm/@tensorflow-models/posenet@2.2.1/dist/posenet.min.js", function() {
					console.log("✅ PoseNet loaded");

					// Step 3: Load Teachable Machine Pose
					loadScript("https://cdn.jsdelivr.net/npm/@teachablemachine/pose@0.8.5/dist/teachablemachine-pose.min.js", async function() {
						console.log("✅ Teachable Machine Pose loaded");
						try {
							const URL = "model/";
							const model = await tmPose.load(URL + "model.json", URL + "metadata.json");
							console.log("✅ Pose model loaded!");

							const webcam = new tmPose.Webcam(224, 224, true);
							await webcam.setup();
							await webcam.play();
							console.log("✅ Webcam is live!");

							document.body.appendChild(webcam.canvas);
							webcam.canvas.style.display = "none";

							let frameCount = 0;
							async function loop() {
								webcam.update();
								const { pose, posenetOutput } = await model.estimatePose(webcam.canvas);
								const prediction = await model.predict(posenetOutput);

								const highest = prediction.reduce((a, b) =>
									a.probability > b.probability ? a : b
								);

								if (["Up", "Left", "Right"].includes(highest.className) && highest.probability > 0.8) {
									window.godotCurrentGesture = highest.className;
								} else {
									window.godotCurrentGesture = "None";
								}

								frameCount++;
								if (frameCount % 30 === 0) {
									console.log("--- Pose Probabilities ---");
									prediction.forEach(p => {
										console.log(p.className + ": " + (p.probability * 100).toFixed(1) + "%");
									});
									console.log("Current gesture: " + window.godotCurrentGesture);
								}

								requestAnimationFrame(loop);
							}
							loop();
						} catch(e) {
							console.error("❌ Error during pose model/webcam setup:", e);
						}
					});
				});
			});
		})();
	""")

	set_process(true)

func _process(_delta):
	var g = JavaScriptBridge.eval("(typeof getGesture !== 'undefined') ? getGesture() : 'None';")
	if g == null:
		g = "None"

	if g != current_gesture:
		current_gesture = g
		print("Gesture: ", current_gesture)

		match current_gesture:
			"Up":
				emit_signal("gesture_up")
			"Left":
				emit_signal("gesture_left")
			"Right":
				emit_signal("gesture_right")
			"None":
				emit_signal("gesture_none")
