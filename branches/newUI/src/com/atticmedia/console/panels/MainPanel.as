package com.atticmedia.console.panels {
	import com.atticmedia.console.events.TextFieldRollOver;	
	
	import flash.events.KeyboardEvent;	
	import flash.geom.Point;	
	import flash.events.MouseEvent;	
	
	import com.atticmedia.console.core.Central;	
	import com.atticmedia.console.core.Style;	
	import com.atticmedia.console.Console;	
	
	import flash.events.TextEvent;	
	import flash.text.TextFieldType;	
	import flash.text.TextField;	
	import flash.text.TextFormat;	
	import flash.geom.Rectangle;	
	import flash.display.Shape;	
	import flash.display.Sprite;
	
	/**
	 * @author LuAye
	 */
	public class MainPanel extends AbstractPanel {
		
		public static const NAME:String = "MainPanel";
		
		private static const _ToolTips:Object = {
				fps:"Frames Per Second",
				mm:"Memory Monitor",
				roller:"Display Roller",
				command:"Command Line"
		};
		
		private var _traceField:TextField;
		private var _menuField:TextField;
		private var _commandField:TextField;
		private var _commandBackground:Shape;
		private var _bottomLine:Shape;
		
		private var _isMinimised:Boolean;
		
		
		public function MainPanel(refs:Central) {
			super(refs);
			name = NAME;
			minimumWidth = 50;
			minimumHeight = 18;
			
			_traceField = new TextField();
			_traceField.name = "traceField";
			_traceField.wordWrap = true;
			_traceField.background  = false;
			_traceField.multiline = true;
			_traceField.styleSheet = style.tracecss;
			_traceField.y = 12;
			addChild(_traceField);
			//
			_menuField = new TextField();
			_menuField.name = "menuField";
			_menuField.styleSheet = style.css;
			_menuField.height = 18;
			_menuField.y = -2;
			registerRollOverTextField(_menuField);
			_menuField.addEventListener(TextFieldRollOver.ROLLOVER, onMenuRollOver, false, 0, true);
			addChild(_menuField);
			//
			_commandBackground = new Shape();
			_commandBackground.name = "commandBackground";
			_commandBackground.graphics.beginFill(style.panelBackgroundColor, 0.1);
			_commandBackground.graphics.drawRoundRect(0, 0, 100, 18,12,12);
			_commandBackground.scale9Grid = new Rectangle(9, 9, 80, 1);
			addChild(_commandBackground);
			//
			_commandField = new TextField();
			_commandField.name = "commandField";
			_commandField.type  = TextFieldType.INPUT;
			_commandField.height = 18;
			_commandField.addEventListener(KeyboardEvent.KEY_DOWN, commandKeyDown, false, 0, true);
			_commandField.addEventListener(KeyboardEvent.KEY_UP, commandKeyUp, false, 0, true);
			_commandField.defaultTextFormat = style.textFormat;
			addChild(_commandField);
			//
			_bottomLine = new Shape();
			_bottomLine.name = "blinkLine";
			_bottomLine.alpha = 0.2;
			addChild(_bottomLine);
			//
			init(420,100,true);
			registerDragger(_menuField);
			updateMenu();
			//
			addEventListener(TextEvent.LINK, linkHandler, false, 0, true);
			//
			//
			_traceField.htmlText = "<p><l1>Happy bug fixing!</l1></p><p><p0>Hows the new Console so far?</p0></p>";
		}
		override public function set width(n:Number):void{
			super.width = n;
			_traceField.width = n;
			_menuField.width = n;
			_commandField.width = n-10;
			_commandBackground.width = n;
			
			_bottomLine.graphics.clear();
			_bottomLine.graphics.lineStyle(1, style.bottomLineColor);
			_bottomLine.graphics.moveTo(10, -1);
			_bottomLine.graphics.lineTo(n-10, -1);
			updateMenu();
		}
		override public function set height(n:Number):void{
			super.height = n;
			var minimize:Boolean = false;
			if(n<(_commandField.visible?42:24)){
				minimize = true;
			}
			if(_isMinimised != minimize){
				registerDragger(_menuField, minimize);
				registerDragger(_traceField, !minimize);
				_isMinimised = minimize;
			}
			_menuField.visible = !minimize;
			_traceField.y = minimize?0:12;
			_traceField.height = n-(_commandField.visible?18:0)-(minimize?0:12);
			var cmdy:Number = n-18;
			_commandField.y = cmdy;
			_commandBackground.y = cmdy;
			_bottomLine.y = _commandField.visible?cmdy:n;
			_traceField.scrollV = _traceField.maxScrollV;
			updateMenu();
		}
		//
		//
		//
		public function updateMenu():void{
			//[global] [C] [traces] [myChannel] [myCh2] [masdf] ...v 
			var str:String = "<r><w><menu>[";
			str += doBold("<a href=\"event:fps\">F</a>", central.master.fpsMode>0);
			str += doBold(" <a href=\"event:mm\">M</a>", central.master.memoryMonitor>0);
			str += doBold(" <a href=\"event:roller\">Ro</a>", central.master.displayRoller);
			str += doBold(" <a href=\"event:ruler\">RL</a>", false);
			str += doBold(" <a href=\"event:command\">CL</a>", commandLine);
			str += " <b>|</b> <a href=\"event:clear\">C</a> <a href=\"event:trace\">T</a> <a href=\"event:priority\">P0</a> <a href=\"event:close\">X</a>";
			//_menuText += (_ruler?"<b>":"")+"<a href=\"event:ruler\">RL</a> "+(_ruler?"</b>":"");
			//_menuText += (_roller?"<b>":"")+"<a href=\"event:roller\">Ro</a> "+(_roller?"</b>":"");
			//_menuText += "<a href=\"event:clear\">C</a> <a href=\"event:trace\">T</a> <a href=\"event:priority\">P"+_priority+"</a> <a href=\"event:alpha\">A</a> <a href=\"event:pause\">P</a> <a href=\"event:help\">H</a> <a href=\"event:close\">X</a>] </font>";
			str += "]</menu> ";
			if(_traceField.scrollV > 1){
				str += " <a href=\"event:scrollUp\">^</a>";
			}else{
				str += " -";
			}
			if(_traceField.scrollV< _traceField.maxScrollV){
				str += " <a href=\"event:scrollDown\">v</a>";
			}else{
				str += " -";
			}
			str += "</w></r>";
			_menuField.htmlText = str;
			_menuField.scrollH = _menuField.maxScrollH;
		}
		private function doBold(str:String, b:Boolean):String{
			if(b) return "<b>"+str+"</b>";
			return str;
		}
		private function onMenuRollOver(e:TextFieldRollOver):void{
			central.tooltip(e.url?_ToolTips[e.url.replace("event:","")]:null, this);
		}
		private function linkHandler(e:TextEvent):void{
			stopDrag();
			if(e.text == "scrollUp"){
				_traceField.scrollV -= 3;
			}else if(e.text == "scrollDown"){
				_traceField.scrollV += 3;
			}else if(e.text == "close"){
				visible = false;
			}else if(e.text == "fps"){
				central.master.fpsMode = central.master.fpsMode>0?0:1;
			}else if(e.text == "mm"){
				central.master.memoryMonitor = central.master.memoryMonitor>0?0:1;
			}else if(e.text == "roller"){
				central.master.displayRoller = !central.master.displayRoller;
			}else if(e.text == "command"){
				commandLine = !commandLine;
			}
			e.stopPropagation();
		}
		//
		// COMMAND LINE
		//
		private function commandKeyDown(e:KeyboardEvent):void{
			
		}
		private function commandKeyUp(e:KeyboardEvent):void{
			
		}
		public function set commandLine (b:Boolean):void{
			if(b){
				_commandField.visible = true;
				_commandBackground.visible = true;
			}else{
				_commandField.visible = false;
				_commandBackground.visible = false;
			}
			this.height = height;
			updateMenu();
		}
		public function get commandLine ():Boolean{
			return _commandField.visible;
		}
	}
}
