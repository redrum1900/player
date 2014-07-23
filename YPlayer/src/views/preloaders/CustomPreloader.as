package views.preloaders
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Cubic;
	import com.pamakids.managers.NiceToolTipManagerImpl;
	import com.youli.messengers.PreloaderMessenger;

	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.ProgressEvent;

	import mx.core.mx_internal;
	import mx.events.FlexEvent;
	import mx.preloaders.IPreloaderDisplay;
	import mx.preloaders.Preloader;

	use namespace mx_internal;

	public class CustomPreloader extends Sprite implements IPreloaderDisplay
	{
		private var _preloader:Sprite;

		public function CustomPreloader()
		{
			super();
			addListeners();
			registerCustomClasses();
		}

		private function addListeners():void
		{
			addEventListener(Event.ADDED_TO_STAGE, onStage);
		}

		[Embed(source="/assets/welcome.png")]
		private var logo:Class;

		private function onStage(event:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onStage);
			image=new logo();
			addChild(image);
			positionImage();
			stage.addEventListener(Event.RESIZE, onResize);
			addEventListener(Event.REMOVED_FROM_STAGE, onRmoved);
		}

		private function onResize(event:Event):void
		{
			positionImage();
		}

		private function positionImage():void
		{
			stageWidth=stage.stageWidth;
			stageHeight=stage.stageHeight;
			if (image)
			{
				image.x=(stageWidth - image.width) / 2;
				image.y=(stageHeight - image.height) / 2;
			}
		}

		private function onRmoved(event:Event):void
		{
			stage.removeEventListener(Event.RESIZE, onResize);
			removeEventListener(Event.REMOVED_FROM_STAGE, onRmoved);
			trace('removed');
		}

		protected function registerCustomClasses():void
		{
			mx.core.Singleton.registerClass("mx.managers::IToolTipManager2", NiceToolTipManagerImpl);
		}

		public function get backgroundAlpha():Number
		{
			return 0;
		}

		public function set backgroundAlpha(value:Number):void
		{
		}

		public function get backgroundColor():uint
		{
			return 0;
		}

		public function set backgroundColor(value:uint):void
		{
		}

		public function get backgroundImage():Object
		{
			return null;
		}

		public function set backgroundImage(value:Object):void
		{
		}

		public function get backgroundSize():String
		{
			return null;
		}

		public function set backgroundSize(value:String):void
		{
		}

		private var image:DisplayObject;

		public function initialize():void
		{
			PreloaderMessenger.listen(PreloaderMessenger.SHOW_APP, showApp);
		}

		private var ready:Boolean;

		private function showApp(e:Event):void
		{
			if (ready)
				playTween();
			else
				ready=true;
			PreloaderMessenger.unlisten(PreloaderMessenger.SHOW_APP, showApp);
		}

		public function set preloader(obj:Sprite):void
		{
			_preloader=obj as Preloader;
			_preloader.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			_preloader.addEventListener(FlexEvent.INIT_COMPLETE, initCompleteHandler);
		}

		protected function initCompleteHandler(event:Event):void
		{
			_preloader.removeEventListener(ProgressEvent.PROGRESS, progressHandler);
			_preloader.removeEventListener(FlexEvent.INIT_COMPLETE, initCompleteHandler);
			if (ready)
				playTween();
			else
				ready=true;
		}

		private function playTween():void
		{
			TweenLite.to(image, 0.5, {alpha: 0, width: 496, height: 359, x: width / 2 - 496 / 2, y: height / 2 - 359 / 2, ease: Cubic.easeOut, onComplete: show});
		}

		private function show():void
		{
			trace('show');
			dispatchEvent(new Event(Event.COMPLETE));
		}

		protected function progressHandler(event:ProgressEvent):void
		{
		}

		private var sw:Number;

		private var sh:Number;

		public function get stageHeight():Number
		{
			return sh;
		}

		public function set stageHeight(value:Number):void
		{
			sh=value;
		}

		public function get stageWidth():Number
		{
			return sw;
		}

		public function set stageWidth(value:Number):void
		{
			sw=value;
		}
	}
}


