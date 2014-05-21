package controllers
{
	import com.pamakids.manager.LoadManager;
	import com.pamakids.models.ResultVO;
	import com.pamakids.services.QNService;
	import com.pamakids.services.ServiceBase;
	import com.pamakids.utils.CloneUtil;
	import com.pamakids.utils.Singleton;
	
	import flash.events.Event;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;
	
	import models.SongVO;
	
	public class API extends Singleton
	{
		private var serviceDic:Dictionary;
		
		public function API()
		{
			serviceDic = new Dictionary();
			QNService.HOST = 'http://yfcdn.qiniudn.com/'
			if(Capabilities.isDebugger)
				ServiceBase.HOST = 'http://localhost:18080/api';
			else
				ServiceBase.HOST = 'http://m.yuefu.com/api';
		}
		
		public static function get instance():API
		{
			return Singleton.getInstance(API);
		}
		
		public var menu:Object
		
		public function getSongList():Array
		{
			var arr:Array = []
			for each(var s:Object in menu.list){
				var songs:Array = s.songs;
				for each(var o:Object in songs){
					o.song.allow_circle = o.allow_circle;
					arr.push(CloneUtil.convertObject(o.song, SongVO));		
				}
			}
			return arr
		}
		
		public function getMenuList():void
		{
			getSB('menu/list', 'GET').call(function(vo:ResultVO):void{
				LoadManager.instance.loadText(QNService.HOST+vo.results[0]['_id']+'.json', function(data:String):void{
					API.instance.menu = JSON.parse(data);
					dispatchEvent(new Event('PLAY'));
				});
			});
		}
		
		public function login(username:String, password:String, callback:Function):void
		{
			getSB('user/login').call(function(vo:ResultVO):void{
				callback(vo);
				if(vo.status)
					getMenuList();
			}, {username:username,password:password});
		}
		
		private function getSB(uri:String, method:String='POST'):ServiceBase
		{
			var s:ServiceBase=serviceDic[uri + method];
			if (s)
				return s;
			s=new ServiceBase(uri, method);
			serviceDic[uri + method]=s;
			return s;
		}
	}
}