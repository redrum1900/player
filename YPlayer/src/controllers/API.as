package controllers
{
	import com.pamakids.components.PAlert;
	import com.pamakids.manager.FileManager;
	import com.pamakids.manager.LoadManager;
	import com.pamakids.managers.PopupBoxManager;
	import com.pamakids.models.ResultVO;
	import com.pamakids.services.QNService;
	import com.pamakids.services.ServiceBase;
	import com.pamakids.utils.CloneUtil;
	import com.pamakids.utils.DateUtil;
	import com.pamakids.utils.NodeUtil;
	import com.pamakids.utils.Singleton;
	import com.youli.nativeApplicationUpdater.NativeApplicationUpdater;

	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.net.SharedObject;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;
	import flash.utils.Timer;

	import models.InsertVO;
	import models.MenuVO;
	import models.SongVO;
	import models.TimeVO;

	import views.SelectCacheView;

	public class API extends Singleton
	{
		public var online:Boolean=true;

		private var serviceDic:Dictionary;
		private var refreshTimer:Timer;

		public function API()
		{
			serviceDic=new Dictionary();
			QNService.HOST='http://yfcdn.qiniudn.com/'
			if (Capabilities.isDebugger)
				ServiceBase.HOST='http://localhost:18080/api';
			else
				ServiceBase.HOST='http://m.yuefu.com/api';
			refreshTimer=new Timer(1000);
			refreshTimer.addEventListener(TimerEvent.TIMER, refreshHandler);
		}

		protected function refreshHandler(event:TimerEvent):void
		{
			if (refreshTimer.currentCount % 60 == 0)
			{
				getSB('/refresh', 'GET').call(function(vo:ResultVO):void
				{
					if (vo.status)
					{
						var menus:Array=FileManager.readFile('menus.yp') as Array;
						if (compareBros(vo.results.bros))
						{
							var so:SharedObject=SharedObject.getLocal('yp');
							so.data.broadcasts=vo.results.bros;
							so.flush();
							initBroadcasts();
						}
						if (compareMenus(menus, vo.results.menus as Array))
						{
							initMenu();
						}
					}
				});
			}
		}

		private function compareBros(arr:Array):Boolean
		{
			var changed:Boolean;
			if (broadcasts)
			{
				if (broadcasts.length != arr.length)
				{
					changed=true;
				}
				else
				{
					for each (var o1:Object in broadcasts)
					{
						var exists:Boolean=false;
						for each (var o2:Object in arr)
						{
							if (o1._id == o2._id)
							{
								exists=true;
								break;
							}
						}
						if (!exists)
						{
							changed=true;
							break;
						}
					}
				}
			}
			else
			{
				changed=true;
			}
			return changed;
		}

		public static function get instance():API
		{
			return Singleton.getInstance(API);
		}

		public var menu:MenuVO;

		public function getSongList():Array
		{
			var arr:Array=[]
			for each (var s:Object in menu.list)
			{
				var songs:Array=s.songs;
				for each (var o:Object in songs)
				{
					o.song.allow_circle=o.allow_circle;
					arr.push(CloneUtil.convertObject(o.song, SongVO));
				}
			}
			return arr
		}

		private function compareMenus(menus:Array, newMenus:Array):Boolean
		{
			var changed:Boolean=false;
			if (!newMenus)
				return false;
			if (!menus || menus.length != newMenus.length)
			{
				FileManager.saveFile('menus.yp', newMenus);
				changed=true;
			}
			else
			{
				for (var i:int=0; i < menus.length; i++)
				{
					var m1:Object=menus[i];
					var m2:Object=newMenus[i];
					if (m1._id != m2._id || m1.updated_at != m2.updated_at)
					{
						changed=true;
						FileManager.saveFile('menus.yp', newMenus);
						break;
					}
				}
			}
			return changed;
		}

		public function getMenuList():void
		{
			if (menu)
				return;
			var menus:Array=FileManager.readFile('menus.yp') as Array;
			if (online)
			{
				getSB('menu/list', 'GET').call(function(vo:ResultVO):void
				{
					if (vo.status)
					{
						if (vo.results.length)
						{
							compareMenus(menus, vo.results as Array);
							initMenu();
						}
						else
						{
							if (!menus)
							{
								PAlert.show('您的播放歌单尚未准备完毕，请联系客服进行添加', '初始化失败', null, function():void
								{
									getMenuList();
								}, PAlert.CONFIRM, '再试一次', '', true);
							}
							else
							{
								initMenu();
							}
						}
					}
					else
					{
						online=false;
						initMenu();
					}
				});
			}
			else
			{
				if (!menus)
				{
					PAlert.show('您的播放歌单尚未准备完毕，请联系客服进行添加并连接网络', '初始化失败', null, function():void
					{
						online=true
						getMenuList();
					}, PAlert.CONFIRM, '再试一次', '', true);
				}
				else
				{
					initMenu();
				}
			}
		}

		[Bindable]
		public var songs:Array;

		public function getRandomSong():SongVO
		{
			var now:Date=new Date();
			var vo:SongVO;
			var arr:Array=[];
			for each (var t:TimeVO in menu.list)
			{
				if (t.begin.getTime() < now.getTime() && t.end.getTime() > now.getTime())
				{
					for each (var s:SongVO in t.songs)
					{
						if (s.allow_circle)
							arr.push(s);
					}
					if (arr.length)
						vo=arr[Math.floor(Math.random() * arr.length)];
				}
			}
			return vo;
		}

		[Bindable]
		public var broadcasts:Array;

		private function initMenu():void
		{
			var menus:Array=FileManager.readFile('menus.yp') as Array;
			if (menus && menus.length)
			{
				var i:int;
				var listMenu:Object;
				var dmMenu:Object;
				var o:Object;
				for (i=0; i < menus.length; i++)
				{
					o=menus[i];
					if (o.type == 1)
					{
						listMenu=o;
						break;
					}
				}
				for (i=0; i < menus.length; i++)
				{
					o=menus[i];
					if (o.type == 2)
					{
						dmMenu=o;
						break;
					}
				}
				var n:Date=new Date();
				n=new Date(n.getFullYear(), n.getMonth(), n.getDate())

				if (!listMenu)
				{
					noPlayList();
					return;
				}
				else
				{
					o=listMenu;
				}

				o.end_date=NodeUtil.getLocalDate(o.end_date);
				if (n.getTime() <= o.end_date.getTime())
				{
					var songMenu:Object;
					var dmMenuO:Object;
					if (dmMenu)
					{
						LoadManager.instance.loadText(QNService.HOST + dmMenu._id + '.json', function(data:String):void
						{
							dmMenuO=JSON.parse(data);
							if (songMenu)
								parseMenu(songMenu, dmMenuO);
						}, dmMenu._id + '.json', online);
					}
					LoadManager.instance.loadText(QNService.HOST + o._id + '.json', function(data:String):void
					{
						songMenu=JSON.parse(data);
						if (dmMenu)
						{
							if (dmMenuO)
								parseMenu(songMenu, dmMenuO);
						}
						else
						{
							parseMenu(songMenu, null);
						}
					}, o._id + '.json', online);
				}
				else
				{
					noPlayList();
				}
			}

			if (!refreshTimer.running)
				refreshTimer.start();
		}

		private function parseMenu(songMenu:Object, dmMenu:Object):void
		{
			var o:Object=songMenu;
			o.end_date=NodeUtil.getTimeDate(o.end_date);
			o.begin_date=NodeUtil.getTimeDate(o.begin_date);
			songs=[];
			dms=[];
			songDMDic=new Dictionary();
			if (dmMenu && dmMenu.dm_list)
			{
				var a:Array=[];
				for each (var dm:Object in dmMenu.dm_list)
				{
					if (dm.day)
					{
						var day:String=new Date().getDay() + '';
						if (dm.day.indexOf(day) == -1)
							continue;
					}
					var ivo:InsertVO=new InsertVO();
					ivo.name=dm.dm.name;
					ivo.duration=dm.dm.duration;
					ivo.url=QNService.HOST + dm.dm.url;
					ivo.repeat=dm.repeat;
					ivo.playTime=DateUtil.getDateByHHMMSS(dm.playTime);
					ivo.interval=dm.interval;
					a.push(ivo);
				}
				dmMenu.dm_list=a;
			}

			if (o.list)
			{
				var playTime:Date;
				var i:int;
				for (i=0; i < o.list.length; i++)
				{
					var oo:Object=o.list[i]
					trace('S', oo.begin);
					oo.begin=DateUtil.getDateByHHMMSS(oo.begin);
					oo.end=DateUtil.getDateByHHMMSS(oo.end);
					playTime=oo.begin;
					var arr:Array=[];
					if (oo.songs)
					{
						var duration:Number=0;
						for (var j:int=0; j < oo.songs.length; j++)
						{
							var s:Object=oo.songs[j];
							var song:SongVO=new SongVO();
							song.allow_circle=s.allow_circle;
							s=s.song;
							song.playTime=DateUtil.clone(playTime);
							song._id=s._id;
							song.url=QNService.HOST + s.url + '?p/1/avthumb/mp3/ab/' + o.quality + 'k';
//							song.url = QNService.HOST+s.url;
							//										song.cover = QNService.getQNThumbnail(s.cover, 200, 200);
							song.name=s.name
							song.duration=s.duration;
							arr.push(song);
							songs.push(song);
							duration=s.duration;
							if (dmMenu && dmMenu.dm_list)
							{
								var t1:Number=playTime.getTime();
								playTime.seconds+=s.duration;
								var t2:Number=playTime.getTime();
								var dmarr:Array=[];
								for each (var dmivo:InsertVO in dmMenu.dm_list)
								{
									var t3:Number=dmivo.playTime.getTime();
									if (t1 <= t3 && t3 <= t2)
									{
										dmarr.push(dmivo);
										dms.push(dmivo);
										songs.push(dmivo);
									}
								}
								if (dmarr.length)
									songDMDic[song]=dmarr;
							}
							else if (s.duration)
								playTime.seconds+=s.duration;
							else
								trace('P', DateUtil.getHMS(song.playTime), s.url, s.name);
						}
					}
					oo.songs=arr;
				}
				o.list=CloneUtil.convertArrayObjects(o.list, TimeVO);
			}
			menu=CloneUtil.convertObject(o, MenuVO);

			initBroadcasts();
			dispatchEvent(new Event('PLAY'));
		}

		public var songDMDic:Dictionary;
		public var dms:Array;

		private function noPlayList():void
		{
			PAlert.show('您的播放歌单尚未准备完毕，请联系客服进行添加并保持网络连接', '初始化失败', null, function():void
			{
				online=true
				getMenuList();
			}, PAlert.CONFIRM, '再试一次', '', true);
		}

		private function initBroadcasts():void
		{
			var so:SharedObject=SharedObject.getLocal('yp');
			var bs:Array=so.data.broadcasts;
			if (bs)
			{
				for each (var o:Object in bs)
				{
					o.playTime=DateUtil.getDateByHHMMSS(o.playTime);
					if (o.url.indexOf('http') == -1)
						o.url=QNService.HOST + o.url;
				}
			}
			broadcasts=CloneUtil.convertArrayObjects(bs, InsertVO);
			dispatchEvent(new Event('bros'));
		}

		[Bindable]
		public var playingIndex:int;

		public function login(username:String, password:String, callback:Function):void
		{
			getSB('user/login').call(function(vo:ResultVO):void
			{
				var so:SharedObject=SharedObject.getLocal('yp');
				var cd:String=so.data.cacheDir;
				var exists:Boolean;
				try
				{
					if (cd)
					{
						var f:File=new File(cd);
						exists=f.isDirectory;
					}
				}
				catch (error:Error)
				{
				}
				if (vo.status)
				{
					ServiceBase.id=vo.results.id + '';
					if (cd && exists)
					{
						FileManager.savedDir=so.data.cacheDir;
						getMenuList();
					}
				}
				else
				{
					FileManager.savedDir=so.data.cacheDir;
				}
				if (!cd || !exists)
				{
					var sv:SelectCacheView=new SelectCacheView();
					PopupBoxManager.popup(sv, function():void
					{
						so=SharedObject.getLocal('yp');
						FileManager.savedDir=so.data.cacheDir;
						getMenuList();
					});
				}
				callback(vo);
			}, {username: username, password: password});
		}

		[Bindable]
		public var updatable:Boolean;

		public var updater:NativeApplicationUpdater;
		public var playingSong:SongVO;

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

