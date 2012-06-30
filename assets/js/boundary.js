// http://rectangleworld.com/blog/archives/358

window.addEventListener("load", windowLoadHandler, false);

//for debug messages
var Debugger = function() { };
Debugger.log = function(message) {
	try {
		console.log(message);
	}
	catch (exception) {
		return;
	}
}

function windowLoadHandler() {
	canvasApp();
}

function canvasSupport() {
	return Modernizr.canvas;
}

function canvasApp() {
	if (!canvasSupport()) {
		return;
	}
	
	var displayCanvas = document.getElementById("canvas1");
	var context = displayCanvas.getContext("2d");
	
	var centerX;
	var centerY;
	var boundaryRad;
	var particleList;
	var numParticles;
	var displayWidth;
	var displayHeight;
	var timer;
	var p;
	var particleColor;
	var particleRad;
	var boundaryRadSquare;
	var spriteSheetCanvas;
	var spriteSheetContext;
	var lastX;
	var lastY;
	var exitX;
	var exitY;
	var exitRad;
	var vx;
	var vy;
	var twiceProjFactor;
	var coreRad;
	var spriteCircleInnerRad, spriteCircleOuterRad, spriteCircleOuterDiam;
	var radSquare;
	var initVelMax;
	var maxVelComp;
	var randAccel;
	var temp;
	var haloEdgeColor,haloOuterColor;
	
	init();
	
	function init() {
		
		numParticles = 50;
		
		particleColor = "#FFFFFF";
		haloEdgeColor = "rgba(255,200,50,0.4)";
		haloOuterColor = "rgba(255,200,50,0)";
		
		particleRad = 24;
		coreRad = 5;
		particleDiam = 2*particleRad;
		displayWidth = displayCanvas.width;
		displayHeight = displayCanvas.height;
		centerX = displayWidth/2;
		centerY = displayHeight/2;
		boundaryRad = 0.5*Math.min(displayWidth,displayHeight) - particleRad - 1;
		boundaryRadSquare = boundaryRad*boundaryRad;
		
		initVelMax = 3.5;
		maxVelComp = 3.5;
		randAccel = 0.2;
				
		particleList = {};
		createParticles();
		
		makeSpriteSheet();
		
		context.fillStyle = "#000000";
		context.fillRect(0,0,displayWidth,displayHeight);
		
		timer = setInterval(onTimer, 1000/40);
	}
	
	function createParticles() {
		var angle;
		var dist;
		var vAngle;
		var vMag;
		for (var i = 0; i < numParticles; i++) {
			angle = Math.random()*2*Math.PI;
			dist = 0.8*boundaryRad*Math.sqrt(Math.random());
			vAngle = Math.random()*2*Math.PI;
			vMag = initVelMax*(0.6 + 0.4*Math.random());
			var newParticle = {	x: dist*Math.cos(angle),
					 			y: dist*Math.sin(angle),
					 			velX: vMag*Math.cos(vAngle),
								velY: vMag*Math.sin(vAngle)}
			if (i > 0) {
				newParticle.next = particleList.first;
			}
			particleList.first = newParticle;				
		}
	}
	
	function makeSpriteSheet() {
		spriteCircleInnerRad = boundaryRad+coreRad;
		spriteCircleOuterRad = boundaryRad+particleRad;
		spriteCircleOuterDiam = 2*spriteCircleOuterRad;

		spriteSheetCanvas = document.createElement('canvas');
		spriteSheetCanvas.width = particleRad*2 + spriteCircleOuterDiam;
		spriteSheetCanvas.height = spriteCircleOuterDiam;
		spriteSheetContext = spriteSheetCanvas.getContext("2d");
		
		//draw particle - halo
		var grad = spriteSheetContext.createRadialGradient(particleRad, particleRad, 0, particleRad, particleRad, particleRad);
		grad.addColorStop(0,haloEdgeColor);
		grad.addColorStop(coreRad/particleRad,haloEdgeColor);
		grad.addColorStop(1,haloOuterColor);
		spriteSheetContext.fillStyle = grad;
		spriteSheetContext.beginPath();
		spriteSheetContext.arc(particleRad, particleRad, particleRad, 0, 2*Math.PI, false);
		spriteSheetContext.closePath();
		spriteSheetContext.fill();
		
		//draw particle - core
		spriteSheetContext.fillStyle = particleColor;
		spriteSheetContext.beginPath();
		spriteSheetContext.arc(particleRad, particleRad, coreRad, 0, 2*Math.PI, false);
		spriteSheetContext.closePath();
		spriteSheetContext.fill();
		
		//boundary circle - outer black
		spriteSheetContext.strokeStyle = "#000000";
		spriteSheetContext.lineWidth = spriteCircleOuterRad - spriteCircleInnerRad;
		spriteSheetContext.beginPath();
		spriteSheetContext.arc(2*particleRad + spriteCircleOuterRad,spriteCircleOuterRad,
								0.5*(spriteCircleOuterRad + spriteCircleInnerRad), 0, 2*Math.PI, false);
		spriteSheetContext.closePath();
		spriteSheetContext.stroke();
		
		//boundary circle - visible rim
		spriteSheetContext.strokeStyle = "#111111";
		spriteSheetContext.lineWidth = 2;
		spriteSheetContext.beginPath();
		spriteSheetContext.arc(2*particleRad + spriteCircleOuterRad,spriteCircleOuterRad,
								spriteCircleInnerRad, 0, 2*Math.PI, false);
		spriteSheetContext.closePath();
		spriteSheetContext.stroke();		
	}

	
	function onTimer() {
		context.globalCompositeOperation = "source-over";
		
		context.fillStyle = "#000000";
		context.fillRect(0,0,displayWidth,displayHeight);
		
		//update and draw particles
		context.globalCompositeOperation = "lighter";
		p = particleList.first;
		while (p != null) {
			//update
			lastX = p.x;
			lastY = p.y;
			
			//random accleration
			p.velX += (1-2*Math.random())*randAccel;
			p.velY += (1-2*Math.random())*randAccel;
			
			//don't let velocity get too large
			if (p.velX > maxVelComp) {
				p.velX = maxVelComp;
			}
			else if (p.velX < -maxVelComp) {
				p.velX = -maxVelComp;
			}
			if (p.velY > maxVelComp) {
				p.velY = maxVelComp;
			}
			else if (p.velY < -maxVelComp) {
				p.velY = -maxVelComp;
			}
			
			p.x += p.velX;
			p.y += p.velY;
			
			//boundary
			radSquare= p.x*p.x + p.y*p.y;
			if (radSquare > boundaryRadSquare) {
				
				//find intersection point with circle. simple method: midpoint
				exitX = (lastX + p.x)/2;
				exitY = (lastY + p.y)/2;
				
				//scale to proper radius
				exitRad = Math.sqrt(exitX*exitX + exitY*exitY);
				exitX *= boundaryRad/exitRad;
				exitY *= boundaryRad/exitRad;
				
				p.x = exitX;
				p.y = exitY;

				//bounce
				twiceProjFactor = 2*(exitX*p.velX + exitY*p.velY)/boundaryRadSquare;
				vx = p.velX - twiceProjFactor*exitX;
				vy = p.velY - twiceProjFactor*exitY;
				p.velX = vx;
				p.velY = vy;
			}
			
			//draw by copying from sprite sheet			
			context.drawImage(spriteSheetCanvas,
								0,0,particleDiam,particleDiam,
								Math.round(centerX + p.x - particleRad),
								Math.round(centerY + p.y - particleRad),
								particleDiam,particleDiam);

			//advance
			p = p.next;
		}
			
		//boundary circle from sprite sheet
		context.globalCompositeOperation = "source-over";
		context.drawImage(spriteSheetCanvas,
							2*particleRad,0,spriteCircleOuterDiam,spriteCircleOuterDiam,
							centerX-spriteCircleOuterRad,centerY-spriteCircleOuterRad,spriteCircleOuterDiam,spriteCircleOuterDiam);
	}
}