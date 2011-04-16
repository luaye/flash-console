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
package com.junkbyte.console.core {
	import com.junkbyte.console.ConsoleConfig;
	import com.junkbyte.console.vos.RemoteSync;
	import com.junkbyte.console.vos.GraphGroup;
	import com.junkbyte.console.vos.Log;
	import com.junkbyte.console.Console;

	import flash.events.EventDispatcher;
	import flash.events.SecurityErrorEvent;
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;
	import flash.system.Security;

	public class Remoting extends EventDispatcher{
		
		public static const REMOTE_PREFIX:String = "R";
		public static const CLIENT_PREFIX:String = "C";
		
		private var _master:Console;
		private var _config:ConsoleConfig;
		private var _isRemoting:Boolean;
		private var _sharedConnection:LocalConnection;
		private var _remoteLinesQueue:Array;
		private var _delayed:int;
		
		private var _remotingPassword:String;
		private var _loggedIn:Boolean;
		private var _canDraw:Boolean;
		
		public function Remoting(m:Console, pass:String) {
			_master = m;
			_config = _master.config;
			_remotingPassword = pass;
		}
		public function set remotingPassword(str:String):void{
			_remotingPassword = str;
			if(_isRemoting && !str) login();
		}
		public function addLineQueue(line:Log):void{
			if(!(_isRemoting && _loggedIn)) return;
			_remoteLinesQueue.push(line.toObject());
			var maxlines:int = _config.maxLines;
			if(_remoteLinesQueue.length > maxlines && maxlines > 0 ){
				_remoteLinesQueue.splice(0,1);
			}
		}
		public function update(graphs:Array, om:Object):void{
			if(_isRemoting){
				if(!_loggedIn) return;
				_delayed++;
				if(_delayed >= _config.remoteDelay){
					_delayed = 0;
					var newQueue:Array = new Array();
					// don't send too many lines at once cause there is 50kb limit with LocalConnection.send
					// Buffer it...
					if(_remoteLinesQueue.length > 10){
						newQueue = _remoteLinesQueue.splice(10);
						// to force update next farme
						_delayed = _config.remoteDelay;
					}
					var a:Array = [];
					for each(var ggroup:GraphGroup in graphs){
						a.push(ggroup.toObject());
					}
					var vo:RemoteSync = new RemoteSync();
					vo.lines = _remoteLinesQueue;
					vo.graphs = a;
					vo.cl = "";
					vo.om = om;
					send("sync", vo);
					_remoteLinesQueue = newQueue;
				}
			}else if(!_master.paused){
				_canDraw = true;
			}
		}
		public function send(command:String, ...args):void{
			var target:String = _config.remotingConnectionName+(REMOTE_PREFIX);
			args = [target, command].concat(args);
			try{
				_sharedConnection.send.apply(this, args);
			}catch(e:Error){
				// don't care
			}
		}
		public function get remoting():Boolean{
			return _isRemoting;
		}
		public function set remoting(newV:Boolean):void{
			_remoteLinesQueue = null;
			if(newV){
				_delayed = 0;
				_remoteLinesQueue = new Array();
				startSharedConnection();
				_sharedConnection.addEventListener(StatusEvent.STATUS, onRemotingStatus);
				_sharedConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR , onRemotingSecurityError);
				try{
					_sharedConnection.connect(_config.remotingConnectionName+CLIENT_PREFIX);
					_master.report("<b>Remoting started.</b> "+getInfo(),-1);
					_isRemoting = true;
					_loggedIn = checkLogin("");
					if(_loggedIn){
						_remoteLinesQueue = _master.getLogsAsObjects();
						send("loginSuccess");
					}else{
						send("requestLogin");
					}
				}catch (error:Error){
					_master.report("Could not create client service. You will not be able to control this console with remote.", 10);
				}
			}else{
				_isRemoting = false;
				close();
			}
		}
		private function onRemotingStatus(e:StatusEvent):void{
			if(e.level == "error") _loggedIn = false;
		}
		private function onRemotingSecurityError(e:SecurityErrorEvent):void{
			_master.report("Remoting security error.", 9);
			printHowToGlobalSetting();
		}
		private function getInfo():String{
			return "</p5>channel:<p5>"+_config.remotingConnectionName+" ("+Security.sandboxType+")";
		}
		private function printHowToGlobalSetting():void{
			_master.report("Make sure your flash file is 'trusted' in Global Security Settings.", -2);
			_master.report("Go to Settings Manager [<a href='event:settings'>click here</a>] &gt; 'Global Security Settings Panel' (on left) &gt; add the location of the local flash (swf) file.", -2);
		}
		private function startSharedConnection():void{
			close();
			_sharedConnection = new LocalConnection();
			_sharedConnection.allowDomain("*");
			_sharedConnection.allowInsecureDomain("*");
			// just for sort of security
			_sharedConnection.client = {
				login:login, gc:_master.gc, fps:fpsRequest, mem:memRequest
			};
		}
		private function fpsRequest(b:Boolean):void{
			_master.fpsMonitor = b;
		}
		private function memRequest(b:Boolean):void{
			_master.memoryMonitor = b;
		}
		public function login(pass:String = null):void{
			if(_loggedIn || checkLogin(pass)){
				_loggedIn = true;
				_remoteLinesQueue = _master.getLogsAsObjects();
				send("loginSuccess");
			}else{
				send("loginFail");
			}
		}
		public function checkLogin(pass:String):Boolean{
			return (!_remotingPassword || _remotingPassword == pass);
		}
		public function close():void{
			if(_sharedConnection){
				try{
					_sharedConnection.close();
				}catch(error:Error){
					_master.report("Remote.close: "+error, 10);
				}
			}
			_sharedConnection = null;
		}
		//
		//
		//
		/*public static function get RemoteIsRunning():Boolean{
			var sCon:LocalConnection = new LocalConnection();
			try{
				sCon.allowInsecureDomain("*");
				sCon.connect(Console.RemotingConnectionName+REMOTE_PREFIX);
			}catch(error:Error){
				return true;
			}
			sCon.close();
			return false;
		}*/
	}
}