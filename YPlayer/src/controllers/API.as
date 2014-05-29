package controllers
{
	import com.pamakids.components.PAlert;
	import com.pamakids.manager.FileManager;
	import com.pamakids.manager.LoadManager;
	import com.pamakids.models.ResultVO;
	import com.pamakids.services.QNService;
	import com.pamakids.services.ServiceBase;
	import com.pamakids.utils.CloneUtil;
	import com.pamakids.utils.DateUtil;
	import com.pamakids.utils.NodeUtil;
	import com.pamakids.utils.Singleton;

	import flash.events.Event;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;

	import models.MenuVO;
	import models.SongVO;
	import models.TimeVO;

	public class API extends Singleton
	{
		public var online:Boolean = true;

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

		public var menu:MenuVO;

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

		private var newMenus:Array;
		public var forceReload:Boolean;

		public function getMenuList():void
		{
			var menus:Array = FileManager.readFile('menus.yp') as Array;
			if(online){
				getSB('menu/list', 'GET').call(function(vo:ResultVO):void{
					if(vo.status){
						if(vo.results.length){
							newMenus = vo.results as Array;
							if(!menus || menus.length != newMenus.length){
								FileManager.saveFile('menus.yp', newMenus);
							}else{
								var changed:Boolean = false;
								for(var i:int=0; i<menus.length; i++){
									var m1:Object = menus[i];
									var m2:Object = newMenus[i];
									if(m1._id != m2._id || m1.updated_at != m2.updated_at){
										changed = true;
										forceReload = true;
										FileManager.saveFile('menus.yp', newMenus);
										break;
									}
								}
							}
							initMenu();
						}else{
							if(!menus){
								PAlert.show('您的播放歌单尚未准备完毕，请联系客服进行添加', '初始化失败', null, function():void{
									getMenuList();
								}, PAlert.CONFIRM, '再试一次', '', true);
							}else{
								initMenu();
							}
						}
					}else{
						online = false;
						initMenu();
					}
				});
			}else{
				if(!menus){
					PAlert.show('您的播放歌单尚未准备完毕，请联系客服进行添加并连接网络', '初始化失败', null, function():void{
						online = true
						getMenuList();
					}, PAlert.CONFIRM, '再试一次', '', true);
				}
			}
		}

		[Bindable]
		public var songs:Array;

		private function initMenu():void
		{
			var menus:Array = FileManager.readFile('menus.yp') as Array;
			if(menus && menus.length){
				var o:Object = menus[0]
				o.end_date = NodeUtil.getTimeDate(o.end_date);
				var n:Date = new Date();
				n = new Date(n.getFullYear(), n.getMonth(), n.getDate())

				if(n.getTime()<=o.end_date.getTime()){
					LoadManager.instance.loadText(QNService.HOST+o._id+'.json', function(data:String):void{
						o = JSON.parse(data);
						o.end_date = NodeUtil.getTimeDate(o.end_date);
						o.begin_date = NodeUtil.getTimeDate(o.begin_date);
						songs = [];
						if(o.list){
							var playTime:Date;
							for each(var oo:Object in o.list){
								oo.begin = DateUtil.getDateByHHMMSS(oo.begin);
								oo.end = DateUtil.getDateByHHMMSS(oo.end);
								playTime = oo.begin;
								var arr:Array = [];
								if(oo.songs){
									var duration:Number=0;
									for(var i:int=0;i<oo.songs.length; i++){
										var s:Object = oo.songs[i];
										var song:SongVO = new SongVO();
										song.allow_circle = s.allow_circle;
										s = s.song;
										song.playTime = DateUtil.clone(playTime);
										playTime.seconds+=s.duration;
										song._id = s._id;
//										song.url = QNService.HOST+s.url+'?p/1/avthumb/mp3/ab/'+o.quality+'k';
										song.url = QNService.HOST+s.url;
//										song.cover = QNService.getQNThumbnail(s.cover, 200, 200);
										song.name = s.name
										song.duration = s.duration;
										arr.push(song);
										songs.push(song);
										duration = s.duration;
									}
								}
								oo.songs = arr;
							}
							o.list = CloneUtil.convertArrayObjects(o.list, TimeVO);
						}
						menu = CloneUtil.convertObject(o, MenuVO);
						dispatchEvent(new Event('PLAY'));
					}, o._id+'.json', true);
				}
			}
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

