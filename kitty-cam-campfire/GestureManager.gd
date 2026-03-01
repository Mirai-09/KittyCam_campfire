extends Node

func _ready():
	print("GestureManager _ready() called")
	
	JavaScriptBridge.eval("""
		(function() {
			if (window.godotGestureInit) return;
			window.godotGestureInit = true;
			window.godotCurrentGesture = "None";
			window.godotGestureProbabilities = { Up: 0, Left: 0, Right: 0, None: 0 };

			window.getGesture = function() {
				return window.godotCurrentGesture || "None";
			};

			window.getGestureProb = function(name) {
				return window.godotGestureProbabilities[name] || 0;
			};

			var tfScript = document.createElement("script");
			tfScript.src = "https://cdn.jsdelivr.net/npm/@tensorflow/tfjs@4.9.0/dist/tf.min.js";
			tfScript.onerror = function() { console.error("FAILED to load TensorFlow.js"); };
			tfScript.onload = function() {
				console.log("✅ TensorFlow.js loaded");
				var tmScript = document.createElement("script");
				tmScript.src = "https://cdn.jsdelivr.net/npm/@teachablemachine/image@0.8/dist/teachablemachine-image.min.js";
				tmScript.onerror = function() { console.error("FAILED to load Teachable Machine"); };
				tmScript.onload = async function() {
					console.log("✅ Teachable Machine loaded");
					try {
						const URL = "model/";
						const model = await tmImage.load(URL + "model.json", URL + "metadata.json");
						console.log("✅ Model loaded!");

						const webcam = new tmImage.Webcam(224, 224, true);
						await webcam.setup();
						await webcam.play();
						console.log("✅ Webcam is live!");

						document.body.appendChild(webcam.canvas);
						webcam.canvas.style.display = "none";

						let frameCount = 0;
						async function loop() {
							webcam.update();
							const prediction = await model.predict(webcam.canvas);

							prediction.forEach(p => {
								window.godotGestureProbabilities[p.className] = p.probability;
							});

							const highest = prediction.reduce((a, b) =>
								a.probability > b.probability ? a : b
							);
							window.godotCurrentGesture = highest.probability > 0.75 ? highest.className : "None";

							frameCount++;
							if (frameCount % 30 === 0) {
								console.log("--- Gesture Probabilities ---");
								prediction.forEach(p => {
									console.log(p.className + ": " + (p.probability * 100).toFixed(1) + "%");
								});
								console.log("Top gesture: " + window.godotCurrentGesture);
							}

							requestAnimationFrame(loop);
						}
						loop();
					} catch(e) {
						console.error("❌ Error during model/webcam setup:", e);
					}
				};
				document.head.appendChild(tmScript);
			};
			document.head.appendChild(tfScript);
		})();
	""")

	set_process(true)

func _process(_delta):
	var left  = JavaScriptBridge.eval("(typeof getGestureProb !== 'undefined') ? getGestureProb('Left') : 0;")
	var right = JavaScriptBridge.eval("(typeof getGestureProb !== 'undefined') ? getGestureProb('Right') : 0;")
	var up    = JavaScriptBridge.eval("(typeof getGestureProb !== 'undefined') ? getGestureProb('Up') : 0;")

	if left  == null: left  = 0.0
	if right == null: right = 0.0
	if up    == null: up    = 0.0

	if Engine.get_process_frames() % 60 == 0:
		print("Left: %.2f | Right: %.2f | Up: %.2f" % [left, right, up])
