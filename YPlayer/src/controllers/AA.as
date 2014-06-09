package controllers
{
	import com.pamakids.utils.Singleton;

	import flash.display.NativeWindow;
	import flash.events.Event;
	import flash.system.Capabilities;

	public class AA extends Singleton
	{
		public var isMac:Boolean;
		public function AA()
		{
			if (Capabilities.os.indexOf('Mac') != -1)
				isMac = true;
		}

		public static function listen(type:String , handler:Function):void
		{
			i.addEventListener(type , handler);
		}

		public static function unlisten(type:String , handler:Function):void
		{
			i.removeEventListener(type , handler);
		}

		public static function say(type:String):void
		{
			i.dispatchEvent(new Event(type));
		}

		public function login():void
		{

		}

		public static function get i():AA
		{
			return Singleton.getInstance(AA);
		}

		public static function centerWindow(nativeWindow:NativeWindow):void
		{
			nativeWindow.x=(Capabilities.screenResolutionX - nativeWindow.width) / 2;
			nativeWindow.y=(Capabilities.screenResolutionY - nativeWindow.height) / 2;
		}
	}
}

