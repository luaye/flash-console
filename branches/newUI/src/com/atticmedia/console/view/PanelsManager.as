package com.atticmedia.console.view {
	import com.atticmedia.console.Console;
	import com.atticmedia.console.view.AbstractPanel;
	
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;		

	/**
	 * @author LuAye
	 */
	public class PanelsManager{
		
		
		private static const USER_GRAPH_PREFIX:String = "graph_";
		
		private var _master:Console;
		private var _mainPanel:MainPanel;
		private var _ruler:Ruler;
		
		private var _tooltipField:TextField;
		
		public function PanelsManager(master:Console, mp:MainPanel) {
			_master = master;
			_tooltipField = new TextField();
			_tooltipField.autoSize = TextFieldAutoSize.CENTER;
			_tooltipField.multiline = true;
			_tooltipField.background = true;
			_tooltipField.backgroundColor = _master.style.tooltipBackgroundColor;
			_tooltipField.styleSheet = _master.style.css;
			_tooltipField.mouseEnabled = false;
			_mainPanel = mp;
			addPanel(_mainPanel);
		}
		public function addPanel(panel:AbstractPanel):void{
			if(_master.contains(_tooltipField)){
				_master.addChildAt(panel, _master.getChildIndex(_tooltipField));
			}else{
				_master.addChild(panel);
			}
			panel.addEventListener(AbstractPanel.STARTED_DRAGGING, onPanelStartDragScale, false,0, true);
			panel.addEventListener(AbstractPanel.STARTED_SCALING, onPanelStartDragScale, false,0, true);
		}
		public function removePanel(n:String):void{
			var panel:AbstractPanel = _master.getChildByName(n) as AbstractPanel;
			if(panel){
				// this removes it self from parent. this way each individual panel can clean up before closing.  
				panel.close();
			}
		}
		public function getPanel(n:String):AbstractPanel{
			return _master.getChildByName(n) as AbstractPanel;
		}
		public function get mainPanel():MainPanel{
			return _mainPanel;
		}
		public function panelExists(n:String):Boolean{
			return (_master.getChildByName(n) as AbstractPanel)?true:false;
		}
		//
		//
		//
		public function get channelsPanel():Boolean{
			return (getPanel(Console.PANEL_CHANNELS) as ChannelsPanel)?true:false;
		}
		public function set channelsPanel(b:Boolean):void{
			if(channelsPanel != b){
				if(b){
					var chpanel:ChannelsPanel = new ChannelsPanel(_master);
					chpanel.x = _mainPanel.x+_mainPanel.width-332;
					chpanel.y = _mainPanel.y-2;
					addPanel(chpanel);
				}else {
					removePanel(Console.PANEL_CHANNELS);
				}
				_mainPanel.updateMenu();
			}
		}
		//
		//
		//
		public function get displayRoller():Boolean{
			return (getPanel(Console.PANEL_ROLLER) as RollerPanel)?true:false;
		}
		public function set displayRoller(n:Boolean):void{
			if(displayRoller != n){
				if(n){
					var roller:RollerPanel = new RollerPanel(_master);
					roller.x = _mainPanel.x+_mainPanel.width-160;
					roller.y = _mainPanel.y+55;
					addPanel(roller);
					roller.start(_master);
				}else{
					removePanel(Console.PANEL_ROLLER);
				}
				_mainPanel.updateMenu();
			}
		}
		//
		//
		//
		public function get fpsMonitor():int{
			var fps:FPSPanel = getPanel(Console.PANEL_FPS) as FPSPanel;
			if(!fps) return 0;
			return 1;
		}
		public function set fpsMonitor(n:int):void{
			if(fpsMonitor != n){
				if(n == 0){
					removePanel(Console.PANEL_FPS);
				}else if(n > 0){
					var fps:FPSPanel = new FPSPanel(_master);
					fps.x = _mainPanel.x+_mainPanel.width-160;
					fps.y = _mainPanel.y+15;
					addPanel(fps);
				}
				_mainPanel.updateMenu();
			}
		}
		//
		//
		//
		public function get memoryMonitor():int{
			var mp:MemoryPanel = getPanel(Console.PANEL_MEMORY) as MemoryPanel;
			if(!mp) return 0;
			return 1;
		}
		public function set memoryMonitor(n:int):void{
			if(memoryMonitor != n){
				if(n == 0){
					removePanel(Console.PANEL_MEMORY);
				}else if(n > 0){
					var mp:MemoryPanel = new MemoryPanel(_master);
					mp.x = _mainPanel.x+_mainPanel.width-80;
					mp.y = _mainPanel.y+15;
					addPanel(mp);
				}
				_mainPanel.updateMenu();
			}
		}
		//
		//
		//
		public function addGraph(n:String, obj:Object, prop:String, col:Number, key:String, rect:Rectangle = null, inverse:Boolean = false):void{
			n = USER_GRAPH_PREFIX+n;
			var graph:GraphingPanel = getPanel(n) as GraphingPanel;
			if(!graph){
				graph = new GraphingPanel(_master, 100,100);
				graph.x = _mainPanel.x + 80;
				graph.y = _mainPanel.y + 20;
				graph.name = n;
			}
			if(rect){
				graph.x = rect.x;
				graph.y = rect.y;
				if(rect.width>0)
					graph.width = rect.width;
				if(rect.height>0)
					graph.height = rect.height;
			}
			graph.inverse = inverse;
			graph.add(obj,prop,col, key);
			addPanel(graph);
		}
		public function removeGraph(n:String, obj:Object = null, prop:String = null):void{
			var graph:GraphingPanel = getPanel(USER_GRAPH_PREFIX+n) as GraphingPanel;
			if(graph){
				if(obj && prop){
					graph.remove(obj, prop);
				}
				if(graph.numInterests <= 0 || !obj || !prop){
					removePanel(graph.name);
				}
			}
		}
		//
		//
		//
		public function tooltip(str:String = null, panel:AbstractPanel = null):void{
			if(str && !rulerActive){
				str = str.replace(/\:\:(.*)/, "<br/><s>$1</s>");
				_master.addChild(_tooltipField);
				_tooltipField.wordWrap = false;
				_tooltipField.htmlText = "<tooltip>"+str+"</tooltip>";
				if(_tooltipField.width>120){
					_tooltipField.width = 120;
					_tooltipField.wordWrap = true;
				}
				_tooltipField.x = _master.mouseX-(_tooltipField.width/2);
				_tooltipField.y = _master.mouseY+20;
				if(panel){
					var txtRect:Rectangle = _tooltipField.getBounds(_master);
					var panRect:Rectangle = new Rectangle(panel.x,panel.y,panel.width,panel.height);
					var doff:Number = txtRect.bottom - panRect.bottom;
					if(doff>0 && (_tooltipField.y - doff)>(_master.mouseY+15)){
						_tooltipField.y -= doff;
					}
					var loff:Number = txtRect.left - panRect.left;
					var roff:Number = txtRect.right - panRect.right;
					if(loff<0){
						_tooltipField.x -= loff;
					}else if(roff>0){
						_tooltipField.x -= roff;
					}
				}
			}else if(_master.contains(_tooltipField)){
				_master.removeChild(_tooltipField);
			}
		}
		//
		//
		//
		public function startRuler():void{
			if(rulerActive){
				return;
			}
			_ruler = new Ruler();
			_ruler.addEventListener(Ruler.EXIT, onRulerExit, false, 0, true);
			_master.addChild(_ruler);
			_ruler.start(_master);
			_mainPanel.updateMenu();
		}
		public function get rulerActive():Boolean{
			return (_ruler && _master.contains(_ruler))?true:false;
		}
		private function onRulerExit(e:Event):void{
			if(_ruler && _master.contains(_ruler)){
				_master.removeChild(_ruler);
			}
			_ruler = null;
			_mainPanel.updateMenu();
		}
		//
		//
		//
		private function onPanelStartDragScale(e:Event):void{
			var target:AbstractPanel = e.currentTarget as AbstractPanel;
			if(target.snapping){
				var X:Array = [0];
				var Y:Array = [0];
				if(_master.stage){
					// this will only work if stage size is not changed or top left aligned
					X.push(_master.stage.stageWidth);
					Y.push(_master.stage.stageHeight);
				}
				var numchildren:int = _master.numChildren;
				for(var i:int = 0;i<numchildren;i++){
					var panel:AbstractPanel = _master.getChildAt(i) as AbstractPanel;
					if(panel && panel.visible){
						X.push(panel.x);
						X.push(panel.x+panel.width);
						Y.push(panel.y);
						Y.push(panel.y+panel.height);
					}
				}
				target.registerSnaps(X, Y);
			}
		}
		
	}
}
