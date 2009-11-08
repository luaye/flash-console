﻿/*
* 
* Copyright (c) 2008-2009 Lu Aye Oo
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

package com.atticmedia.console.view {
	import flash.system.SecurityPanel;
	import flash.system.Security;
	import com.atticmedia.console.Console;
	import com.atticmedia.console.core.CommandLine;
	import com.atticmedia.console.core.LogLineVO;
	import com.atticmedia.console.events.TextFieldRollOver;
	
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;		

	public class MainPanel extends AbstractPanel {
		
		private static const CHANNELS_IN_MENU:int = 5;
		
		public static const TOOLTIPS:Object = {
				fps:"Frames Per Second",
				mm:"Memory Monitor",
				roller:"Display Roller::Map the display list under your mouse",
				ruler:"Screen Ruler::Measure the distance and angle between two points on screen.",
				command:"Command Line",
				clear:"Clear log",
				trace:"Trace",
				pause:"Pause logging",
				resume:"Resume logging",
				priority:"Priority filter",
				channels:"Expand channels",
				close:"Close",
				closemain:"Close::Type password to show again",
				viewall:"View all channels",
				defaultch:"Default channel::Logs with no channel",
				consolech:"Console channel::Logs generated from Console",
				channel:"Change channel::Hold shift to select multiple channels",
				scrollUp:"Scroll up",
				scrollDown:"Scroll down",
				scope:"Current scope::(CommandLine)"
		};
		
		private var _traceField:TextField;
		private var _menuField:TextField;
		private var _commandPrefx:TextField;
		private var _commandField:TextField;
		private var _commandBackground:Shape;
		private var _bottomLine:Shape;
		private var _isMinimised:Boolean;
		private var _shift:Boolean;
		private var _canUseTrace:Boolean;
		
		private var _channels:Array;
		private var _lines:Array;
		private var _commandsHistory:Array = [];
		private var _commandsInd:int;
		
		private var _needUpdateMenu:Boolean;
		private var _needUpdateTrace:Boolean;
		private var _lockScrollUpdate:Boolean;
		private var _atBottom:Boolean = true;
		
		public function MainPanel(m:Console, lines:Array, channels:Array) {
			super(m);
			
			_canUseTrace = (Capabilities.playerType=="External"||Capabilities.isDebugger);
			
			_channels = channels;
			_lines = lines;
			name = Console.PANEL_MAIN;
			minimumWidth = 50;
			minimumHeight = 18;
			
			_traceField = new TextField();
			_traceField.name = "traceField";
			_traceField.wordWrap = true;
			_traceField.background  = false;
			_traceField.multiline = true;
			_traceField.styleSheet = style.css;
			_traceField.y = 12;
			_traceField.addEventListener(Event.SCROLL, onTraceScroll, false, 0, true);
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
			_commandBackground.graphics.beginFill(style.commandLineColor, 0.1);
			_commandBackground.graphics.drawRoundRect(0, 0, 100, 18,12,12);
			_commandBackground.scale9Grid = new Rectangle(9, 9, 80, 1);
			addChild(_commandBackground);
			//
			_commandField = new TextField();
			_commandField.name = "commandField";
			_commandField.type  = TextFieldType.INPUT;
			_commandField.x = 40;
			_commandField.height = 18;
			_commandField.addEventListener(KeyboardEvent.KEY_DOWN, commandKeyDown, false, 0, true);
			_commandField.addEventListener(KeyboardEvent.KEY_UP, commandKeyUp, false, 0, true);
			_commandField.defaultTextFormat = style.textFormat;
			addChild(_commandField);
			
			_commandPrefx = new TextField();
			_commandPrefx.name = "commandPrefx";
			_commandPrefx.type  = TextFieldType.DYNAMIC;
			_commandPrefx.x = 2;
			_commandPrefx.height = 18;
			_commandPrefx.selectable = false;
			_commandPrefx.styleSheet = style.css;
			_commandPrefx.text = " ";
			_commandPrefx.addEventListener(MouseEvent.MOUSE_DOWN, onCmdPrefMouseDown, false, 0, true);
			_commandPrefx.addEventListener(MouseEvent.MOUSE_MOVE, onCmdPrefRollOverOut, false, 0, true);
			_commandPrefx.addEventListener(MouseEvent.ROLL_OUT, onCmdPrefRollOverOut, false, 0, true);
			addChild(_commandPrefx);
			//
			_bottomLine = new Shape();
			_bottomLine.name = "blinkLine";
			_bottomLine.alpha = 0.2;
			addChild(_bottomLine);
			
			_commandField.visible = false;
			_commandPrefx.visible = false;
			_commandBackground.visible = false;
			//
			init(420,100,true);
			registerDragger(_menuField);
			//
			addEventListener(TextEvent.LINK, linkHandler, false, 0, true);
			addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle, false, 0, true);
			addEventListener(Event.REMOVED_FROM_STAGE, stageRemovedHandle, false, 0, true);
			
			master.cl.addEventListener(CommandLine.CHANGED_SCOPE, onUpdateCommandLineScope, false, 0, true);
		}
		

		private function stageAddedHandle(e:Event=null):void{
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler, false, 0, true);
		}
		private function stageRemovedHandle(e:Event=null):void{
			stage.removeEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
		}
		private function onCmdPrefRollOverOut(e : MouseEvent) : void {
			master.panels.tooltip(e.type==MouseEvent.MOUSE_MOVE?TOOLTIPS["scope"]:"", this);
		}
		private function onCmdPrefMouseDown(e : MouseEvent) : void {
			stage.focus = _commandField;
			_commandField.setSelection(_commandField.text.length, _commandField.text.length);
		}
		private function keyDownHandler(e:KeyboardEvent):void{
			if(e.keyCode == Keyboard.SHIFT){
				_shift = true;
			}
		}
		private function keyUpHandler(e:KeyboardEvent):void{
			if(e.keyCode == Keyboard.SHIFT){
				_shift = false;
			}
		}
		public function update(changed:Boolean):void{
			if(visible){
				if(_bottomLine.alpha>0){
					_bottomLine.alpha -= 0.25;
				}
				if(changed){
					_bottomLine.alpha = 1;
					_needUpdateMenu = true;
					_needUpdateTrace = true;
				}
				if(_needUpdateTrace){
					_needUpdateTrace = false;
					_updateTraces(true);
				}
				if(_needUpdateMenu){
					_needUpdateMenu = false;
					_updateMenu();
				}
			}
		}
		public function updateToBottom():void{
			_atBottom = true;
			_needUpdateTrace = true;
		}
		public function updateTraces(instant:Boolean = false):void{
			if(instant){
				_updateTraces();
			}else{
				_needUpdateTrace = true;
			}
		}
		private function _updateTraces(onlyBottom:Boolean = false):void{
			// TODO: onlyBottom: when you are scrolled up, it doesnt update for new lines, because
			// you won't see them while scrolled up anyway... (it increase performace a lot on long logs)
			// BUT scroll up, add lots of new lines, scroll back down,
			// you'll see it jumps to the bottom of log which can be annoying in rare cases
			// 
			if(_atBottom) {
				updateBottom(); 
			}else if(!onlyBottom){
				updateFull();
			}
		}
		private function updateFull():void{
			var str:String = "";
			for each (var line:LogLineVO in _lines ){
				if(master.lineShouldShow(line)){
					str += makeLine(line);
				}
			}
			_lockScrollUpdate = true;
			_traceField.htmlText = str;
			_lockScrollUpdate = false;
		}
		private function updateBottom():void{
			var linesLeft:int = Math.round(_traceField.height/10);
			var numLines:int = _lines.length;
			var lines:Array = new Array();
			for(var i:int=numLines-1;i>=0;i--){
				var line:LogLineVO = _lines[i];
				if(master.lineShouldShow(line)){
					linesLeft--;
					lines.push(makeLine(line));
					if(linesLeft<=0){
						break;
					}
				}
			}
			_lockScrollUpdate = true;
			_traceField.htmlText = lines.reverse().join("");
			_traceField.scrollV = _traceField.maxScrollV;
			_lockScrollUpdate = false;
		}
		private function makeLine(line:LogLineVO):String{
			var str:String = "";
			var txt:String = line.text;
			if(master.prefixChannelNames && (master.viewingChannels.indexOf(Console.GLOBAL_CHANNEL)>=0 || master.viewingChannels.length>1) && line.c != master.defaultChannel){
				txt = "[<a href=\"event:channel_"+line.c+"\">"+line.c+"</a>] "+txt;
			}
			var ptag:String = "p"+line.p;
			str += "<p><"+ptag+">" + txt + "</"+ptag+"></p>";
			return str;
		}
		private function onTraceScroll(e:Event):void{
			if(_lockScrollUpdate) return;
			updateMenu();
			var bottom:Boolean = _traceField.scrollV >= _traceField.maxScrollV-1;
			if(_atBottom !=bottom){
				var diff:int = _traceField.maxScrollV-_traceField.scrollV;
				_atBottom = bottom;
				updateTraces(true);
				_traceField.scrollV = _traceField.maxScrollV-diff;
			}
		}
		override public function set width(n:Number):void{
			_lockScrollUpdate = true;
			super.width = n;
			_traceField.width = n;
			_menuField.width = n;
			_commandField.width = width-15-_commandField.x;
			_commandBackground.width = n;
			
			_bottomLine.graphics.clear();
			_bottomLine.graphics.lineStyle(1, style.bottomLineColor);
			_bottomLine.graphics.moveTo(10, -1);
			_bottomLine.graphics.lineTo(n-10, -1);
			onUpdateCommandLineScope();
			_atBottom = true;
			_needUpdateMenu = true;
			_needUpdateTrace = true;
			_lockScrollUpdate = false;
		}
		override public function set height(n:Number):void{
			_lockScrollUpdate = true;
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
			_traceField.height = n-(_commandField.visible?16:0)-(minimize?0:12);
			var cmdy:Number = n-18;
			_commandField.y = cmdy;
			_commandPrefx.y = cmdy;
			_commandBackground.y = cmdy;
			_bottomLine.y = _commandField.visible?cmdy:n;
			_atBottom = true;
			_needUpdateMenu = true;
			_needUpdateTrace = true;
			_lockScrollUpdate = false;
		}
		//
		//
		//
		public function updateMenu(instant:Boolean = false):void{
			if(instant){
				_updateMenu();
			}else{
				_needUpdateMenu = true;
			}
		}
		private function _updateMenu():void{
			var str:String = "<r><w>";
			if(!master.channelsPanel){
				str += getChannelsLink(true);
			}
			str += "<menu>[ <b>";
			str += doActive("<a href=\"event:fps\">F</a>", master.fpsMonitor>0);
			str += doActive(" <a href=\"event:mm\">M</a>", master.memoryMonitor>0);
			if(master.commandLinePermission>0){
				str += doActive(" <a href=\"event:command\">CL</a>", commandLine);
			}
			if(!master.remote){
				str += doActive(" <a href=\"event:roller\">Ro</a>", master.displayRoller);
				str += doActive(" <a href=\"event:ruler\">RL</a>", master.panels.rulerActive);
			}
			str += " ¦</b>";
			if(_canUseTrace){
				str += doActive(" <a href=\"event:trace\">T</a>", master.tracing);
			}
			str += " <a href=\"event:priority\">P"+master.priority+"</a>";
			str += doActive(" <a href=\"event:pause\">P</a>", master.paused);
			str += " <a href=\"event:clear\">C</a> <a href=\"event:close\">X</a>";
			
			str += " ]</menu> ";
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
		public function getChannelsLink(limited:Boolean):String{
			var str:String = "<chs>";
			var len:int = _channels.length;
			if(limited && len>CHANNELS_IN_MENU) len = CHANNELS_IN_MENU;
			for(var ci:int = 0; ci<len;  ci++){
				var channel:String = _channels[ci];
				var channelTxt:String = (master.viewingChannels.indexOf(channel)>=0) ? "<ch><b>"+channel+"</b></ch>" : channel;
				channelTxt = channel==master.defaultChannel? "<i>"+channelTxt+"</i>" : channelTxt;
				str += "<a href=\"event:channel_"+channel+"\">["+channelTxt+"]</a> ";
			}
			if(limited){
				str += "<ch><a href=\"event:channels\"><b>"+(_channels.length>len?"...":".")+"</b>^ </a></ch>";
			}
			str += "</chs> ";
			return str;
		}
		private function doActive(str:String, b:Boolean):String{
			if(b) return "<y>"+str+"</y>";
			return str;
		}
		public function onMenuRollOver(e:TextFieldRollOver, src:AbstractPanel = null):void{
			if(src==null) src = this;
			var txt:String = e.url?e.url.replace("event:",""):"";
			if(txt == "channel_"+Console.GLOBAL_CHANNEL){
				txt = TOOLTIPS["viewall"];
			}else if(txt == "channel_"+ master.defaultChannel) {
				txt = TOOLTIPS["defaultch"];
			}else if(txt == "channel_"+ Console.CONSOLE_CHANNEL) {
				txt = TOOLTIPS["consolech"];
			}else if(txt.indexOf("channel_")==0) {
				txt = TOOLTIPS["channel"];
			}else if(txt == "pause"){
				if(master.paused)
					txt = TOOLTIPS["resume"];
				else
					txt = TOOLTIPS["pause"];
			}else if(txt == "close" && src == this){
				txt = TOOLTIPS["closemain"];
			}else{
				txt = TOOLTIPS[txt];
			}
			master.panels.tooltip(txt, src);
		}
		private function linkHandler(e:TextEvent):void{
			_menuField.setSelection(0, 0);
			stopDrag();
			if(e.text == "scrollUp"){
				_traceField.scrollV -= 3;
			}else if(e.text == "scrollDown"){
				_traceField.scrollV += 3;
			}else if(e.text == "pause"){
				if(master.paused){
					master.paused = false;
					master.panels.tooltip(TOOLTIPS["pause"], this);
				}else{
					master.paused = true;
					master.panels.tooltip(TOOLTIPS["resume"], this);
				}
			}else if(e.text == "trace"){
				master.tracing = !master.tracing;
				if(master.tracing){
					master.report("Tracing turned [<b>On</b>]",-1);
				}else{
					master.report("Tracing turned [<b>Off</b>]",-1);
				}
			}else if(e.text == "close"){
				master.panels.tooltip();
				visible = false;
				dispatchEvent(new Event(AbstractPanel.CLOSED));
			}else if(e.text == "channels"){
				master.channelsPanel = !master.channelsPanel;
			}else if(e.text == "fps"){
				master.fpsMonitor = master.fpsMonitor>0?0:1;
			}else if(e.text == "priority"){
				if(master.priority<10){
					master.priority++;
				}else{
					master.priority = 0;
				}
			}else if(e.text == "mm"){
				master.memoryMonitor = master.memoryMonitor>0?0:1;
			}else if(e.text == "roller"){
				master.displayRoller = !master.displayRoller;
			}else if(e.text == "ruler"){
				master.panels.tooltip();
				master.panels.startRuler();
			}else if(e.text == "command"){
				commandLine = !commandLine;
			}else if(e.text == "clear"){
				master.clear();
			}else if(e.text == "settings"){
				master.report("A new window should open in browser. If not, try searching for 'Flash Player Global Security Settings panel' online :)", -1);
				Security.showSettings(SecurityPanel.SETTINGS_MANAGER);
			}else if(e.text.substring(0,8) == "channel_"){
				onChannelPressed(e.text.substring(8));
			}else if(e.text.substring(0,5) == "clip_"){
				var str:String = "/remap "+e.text.substring(5);
				master.runCommand(str);
			}else if(e.text.substring(0,6) == "sclip_"){
				//var str:String = "/remap 0|"+e.text.substring(6);
				master.runCommand("/remap 0"+Console.MAPPING_SPLITTER+e.text.substring(6));
				//master.cl.reMap(e.text.substring(6), stage);
			}
			_menuField.setSelection(0, 0);
			e.stopPropagation();
		}
		public function onChannelPressed(chn:String):void{
			var current:Array = master.viewingChannels.concat();
			if(_shift && master.viewingChannel != Console.GLOBAL_CHANNEL && chn != Console.GLOBAL_CHANNEL){
				var ind:int = current.indexOf(chn);
				if(ind>=0){
					current.splice(ind,1);
					if(current.length == 0){
						current.push(Console.GLOBAL_CHANNEL);
					}
				}else{
					current.push(chn);
				}
				master.viewingChannels = current;
			}else{
				master.viewingChannel = chn;
			}
		}
		//
		// COMMAND LINE
		//
		private function commandKeyDown(e:KeyboardEvent):void{
			e.stopPropagation();
		}
		private function commandKeyUp(e:KeyboardEvent):void{
			if(!master.enabled){
				return;
			}
			if( e.keyCode == 13){
				master.runCommand(_commandField.text);
				_commandsHistory.unshift(_commandField.text);
				_commandsInd = -1;
				_commandField.text = "";
				// maximum 20 commands history
				if(_commandsHistory.length>20){
					_commandsHistory.splice(20);
				}
			}else if( e.keyCode == 38 ){
				// if its back key for first time, store the current key
				if(_commandField.text && _commandsInd<0){
					_commandsHistory.unshift(_commandField.text);
					_commandsInd++;
				}
				if(_commandsInd<(_commandsHistory.length-1)){
					_commandsInd++;
					_commandField.text = _commandsHistory[_commandsInd];
					_commandField.setSelection(_commandField.text.length, _commandField.text.length);
				}else{
					_commandsInd = _commandsHistory.length;
					_commandField.text = "";
				}
			}else if( e.keyCode == 40){
				if(_commandsInd>0){
					_commandsInd--;
					_commandField.text = _commandsHistory[_commandsInd];
					_commandField.setSelection(_commandField.text.length, _commandField.text.length);
				}else{
					_commandsInd = -1;
					_commandField.text = "";
				}
			}
			e.stopPropagation();
		}
		private function onUpdateCommandLineScope(e:Event=null):void{
			if(!master.remote) updateCLScope(master.cl.scopeString);
		}
		public function updateCLScope(str:String):void{
			_commandPrefx.autoSize = TextFieldAutoSize.LEFT;
			_commandPrefx.htmlText = "<w><p1>"+str+":</p1></w>";
			var w:Number = width-48;
			if(_commandPrefx.width > 120 || _commandPrefx.width > w){
				_commandPrefx.autoSize = TextFieldAutoSize.NONE;
				_commandPrefx.width = w>120?120:w;
				_commandPrefx.scrollH = _commandPrefx.maxScrollH;
			}
			_commandField.x = _commandPrefx.width+2;
			_commandField.width = width-15-_commandField.x;
		}
		public function set commandLine (b:Boolean):void{
			if(b && master.commandLinePermission>0){
				_commandField.visible = true;
				_commandPrefx.visible = true;
				_commandBackground.visible = true;
			}else{
				_commandField.visible = false;
				_commandPrefx.visible = false;
				_commandBackground.visible = false;
			}
			this.height = height;
		}
		public function get commandLine ():Boolean{
			return _commandField.visible;
		}
	}
}