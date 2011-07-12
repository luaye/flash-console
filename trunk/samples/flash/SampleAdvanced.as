﻿/*
* 
* Copyright (c) 2008-2010 Lu Aye Oo
* 
* @author 		Lu Aye Oo
* 
* http://code.google.com/p/flash-console/
* 
*
* This software is provided 'as-is', without any express or implied
* warranty.  In no event will the authors be held liable for any damages
* arising from the use of this software.
* Permission is granted to anyone to use this software for any purpose,
* including commercial applications, and to alter it and redistribute it
* freely, subject to the following restrictions:
* 1. The origin of this software must not be misrepresented; you must not
* claim that you wrote the original software. If you use this software
* in a product, an acknowledgment in the product documentation would be
* appreciated but is not required.
* 2. Altered source versions must be plainly marked as such, and must not be
* misrepresented as being the original software.
* 3. This notice may not be removed or altered from any source distribution.
* 
*/
package 
{
	import com.junkbyte.console.addons.htmlexport.ConsoleHtmlExport;
	import com.junkbyte.console.Cc;

	import flash.display.*;
	import flash.geom.Rectangle;

	[SWF(width='700',height='300',backgroundColor='0xFFFFFF',frameRate='30')]
	// Might want to add compile argument: -use-network=false -debug=true
	
	public dynamic class SampleAdvanced extends MovieClip{
		
		private var temp:Object = {object1:{subObj:{text:"Some randome text", number:123}, subArr:[2,3,4,5]}, object2:{arr:[3,4,5]}};
		
		public function SampleAdvanced() {
			stage.scaleMode = StageScaleMode.NO_SCALE;
			//
			// SET UP - only required once
			//
			
			Cc.startOnStage(this, "`"); // "`" - change for password. This will start hidden
			Cc.visible = true; // show console, because having password hides console.
			Cc.commandLine = true; // enable command line
			//Cc.memoryMonitor = true;
			//Cc.fpsMonitor = true;
			//Cc.displayRoller = true;
			
			Cc.config.commandLineAllowed = true;
			Cc.width = 700;
			Cc.height = 300;
			Cc.config.remotingPassword = ""; // Just so that remote don't ask for password
			Cc.remoting = true;
			
			Cc.addMenu("T1", Cc.log, ["Greetings 1"], "This is a test menu 1");
			Cc.addMenu("T2", Cc.log, ["Greetings 2"], "This is a test menu 2");
			Cc.addMenu("spam100k", spam, [100000]);
			//
			// End of setup
			//
			Cc.log("Lets try some object linking...");
			Cc.info("Here is a link to stage: ", stage);
			Cc.info("Here is a link to Cc class", Cc);
			Cc.info("Here is a link to Console instance", Cc.instance);
			//
			// HTML text
			Cc.addHTML("Here is HTML <font color='#ff00ff'>purple <b>bold</b> <b><i>and</i></b> <i>italic</i></font> text.");
			Cc.addHTMLch("html", 8, "Mix objects inside html <p9>like this <i><b>&gt;", this,"&lt;</b></i></p9>");
			
			Cc.log("___");
			
			// explode an object into its values..
			Cc.log("Cc.explode() test:");
			Cc.explode(temp);
			
			Cc.log("___");
			Cc.info("Try the new search highlighting... Type '/filter link' in commandline below.");
			//
			Cc.addSlashCommand("test", function():void{ Cc.log("Do the test!");} );
			Cc.addSlashCommand("test2", function(param:String):void{Cc.log("Do the test 2 with param string:", param);} );
			
			//
			//Graphing feature examples
			//Graph the current mouseX and mouseY values
			Cc.addGraph("mouse", this,"mouseX", 0xff3333,"X", new Rectangle(560,180,80,80), true);
			Cc.addGraph("mouse", this,"mouseY", 0x3333ff,"Y");
			// Sine wave graph generated by commandline execution, very expensive way to graph but it works :)
			Cc.addGraph("mouse", this,"(Math.sin(flash.utils.getTimer()/1000)*300)+300", 0x119911,"sine"); 
			
			//
			// Garbage collection monitor
			var aSprite:Sprite = new Sprite();
			Cc.watch(aSprite, "aSprite");
			aSprite = null;
			// it probably won't get garbage collected straight away,
			// but if you have debugger version of flash player installed,
			// you can open memory monitor (M) and then press G in that panel to force garbage collect
			// You will see "[C] GARBAGE COLLECTED 1 item(s): aSprite"
			
			
			// register 'export' button, which exports logs to HTML. (This is an addon).
			// source file located at samples/addons/  com.junkbyte.console.addons.htmlexport.ConsoleHtmlExport
			// requires JSON: com.adobe.serialization.json.JSON
			ConsoleHtmlExport.register();
			
			
			// Test of Cc.stack,  If you have debugger version installed you will see a stack trace like:
			// HELLO
			//  @ SampleAdvanced/e()
			//  @ SampleAdvanced/d()
			//  @ SampleAdvanced/c()
			a(); // see function e() below
			
		}
		private function a():void{
			b();
		}
		private function b():void{
			c();
		}
		private function c():void{
			d();
		}
		private function d():void{
			e();
		}
		private function e():void{
			Cc.stack("Hello from stack trace.");
		}
		private function spam(chars:int):void{
			var str:String = "";
			while(str.length < chars){
				str += "12345678901234567890123456789012345678901234567890123456789012345678901234567890";
			}
			Cc.log(str.substring(0, chars));
			Cc.log("<<",chars,"chars.");
		}
	}
}
