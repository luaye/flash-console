package com.junkbyte.console.modules.stayOnTop
{
    import com.junkbyte.console.ConsoleLevel;
    import com.junkbyte.console.core.ConsoleModule;
    import com.junkbyte.console.view.ConsoleLayer;
    
    import flash.display.DisplayObjectContainer;

    public class ConsoleStayOnTopModule extends ConsoleModule
    {

        private var attemptsLeft:uint;

        public function ConsoleStayOnTopModule(numOfAttempts:uint = 50)
        {
            attemptsLeft = numOfAttempts;
        }
		
		override protected function registeredToConsole():void
        {
            super.registeredToConsole();
			
			modules.ticker.addUpdateViewCallback(onUpdateView);
        }
		
		override protected function unregisteredFromConsole():void
		{
			super.unregisteredFromConsole();
			
			modules.ticker.removeUpdateViewCallback(onUpdateView);
		}

        private function onUpdateView(deltaTime:uint):void
        {
            var layer:ConsoleLayer = console.layer;
            var parent:DisplayObjectContainer = layer.parent;
            if (parent != null && parent.getChildAt(parent.numChildren - 1) != layer && attemptsLeft > 0)
            {
                attemptsLeft--;
                parent.addChild(layer);
                console.logger.report("Moved console on top by ConsoleStayOnTopModule. " + attemptsLeft + " attempts left.", ConsoleLevel.CONSOLE_STATUS);
            }
        }
    }
}