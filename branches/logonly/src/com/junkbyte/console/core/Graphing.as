/*
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
	import flash.system.System;
	import flash.utils.getTimer;

	import com.junkbyte.console.vos.GraphInterest;
	import com.junkbyte.console.vos.GraphGroup;

	public class Graphing {
		
		private var _groups:Array = [];
		
		private var _fpsGroup:GraphGroup;
		private var _memGroup:GraphGroup;
		
		private var _previousTime:Number = -1;
		private var _report:Function;
		
		public function Graphing(reporter:Function){
			_report = reporter;
		}
		
		public function get fpsMonitor():Boolean{
			return _fpsGroup!=null;
		}
		public function set fpsMonitor(b:Boolean):void{
			if(b != fpsMonitor){
				if(b) {
					_fpsGroup = addSpecialGroup(GraphGroup.TYPE_FPS);
					_fpsGroup.low = 0;
					_fpsGroup.fixed = true;
					_fpsGroup.averaging = 30;
				} else{
					_previousTime = -1;
					var index:int = _groups.indexOf(_fpsGroup);
					if(index>=0) _groups.splice(index, 1);
					_fpsGroup = null;
				}
			}
		}
		//
		public function get memoryMonitor():Boolean{
			return _memGroup!=null;
		}
		public function set memoryMonitor(b:Boolean):void{
			if(b != memoryMonitor){
				if(b) {
					_memGroup = addSpecialGroup(GraphGroup.TYPE_MEM);
					_memGroup.freq = 10;
				} else{
					var index:int = _groups.indexOf(_memGroup);
					if(index>=0) _groups.splice(index, 1);
					_memGroup = null;
				}
			}
		}
		private function addSpecialGroup(type:int):GraphGroup{
			var group:GraphGroup = new GraphGroup("special");
			group.type = type;
			_groups.push(group);
			var graph:GraphInterest = new GraphInterest("special");
			if(type == GraphGroup.TYPE_FPS) {
				graph.col = 0xFF3333;
				graph.avg = 0;
			}else{
				graph.col = 0x5060FF;
			}
			group.interests.push(graph);
			return group;
		}
		public function update(fps:Number = 0):Array{
			var interest:GraphInterest;
			var v:Number;
			for each(var group:GraphGroup in _groups){
				var ok:Boolean = true;
				if(group.freq>1){
					group.idle++;
					if(group.idle<group.freq){
						ok = false;
					}else{
						group.idle = 0;
					}
				}
				if(ok){
					var typ:uint = group.type;
					var averaging:uint = group.averaging;
					var interests:Array = group.interests;
					if(typ == GraphGroup.TYPE_FPS){
						group.hi = fps;
						interest = interests[0];
						var time:int = getTimer();
						if(_previousTime >= 0){
							var mspf:Number = time-_previousTime;
							v = 1000/mspf;
							interest.setValue(v, averaging);
						}
						_previousTime = time;
					}else if(typ == GraphGroup.TYPE_MEM){
						interest = interests[0];
						v = Math.round(System.totalMemory/10485.76)/100;
						group.updateMinMax(v);
						interest.setValue(v, averaging);
					}
				}
			}
			return _groups;
		}
	}
}