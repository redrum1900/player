package controllers
{
	import com.pamakids.utils.Singleton;
	
	import flash.display.NativeWindow;
	import flash.system.Capabilities;
	
	public class AC extends Singleton
	{
		public var isMac:Boolean;
		public function AC()
		{
			if (Capabilities.os.indexOf('Mac') != -1)
				isMac = true;
		}
		
		public function login():void
		{
			
		}
		
		public static function get i():AC
		{
			return Singleton.getInstance(AC);
		}
		
		public static function centerWindow(nativeWindow:NativeWindow):void
		{
			nativeWindow.x=(Capabilities.screenResolutionX - nativeWindow.width) / 2;
			nativeWindow.y=(Capabilities.screenResolutionY - nativeWindow.height) / 2;
		}
	}
}