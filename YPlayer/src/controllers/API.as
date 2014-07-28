package controllers
{
	import com.greensock.TweenLite;
	import com.pamakids.components.PAlert;
	import com.pamakids.events.ODataEvent;
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
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;
	import flash.utils.Timer;

	import models.InsertVO;
	import models.MenuVO;
	import models.SongVO;
	import models.TimeVO;

	import views.MessageWindow;
	import views.SelectCacheView;
	import views.windows.PrepareWindow;

	public class API extends Singleton
	{
		[Bindable]
		public var local:Boolean=false;
		public var online:Boolean=true;
		public var isTest:Boolean=true;

		public var enableFunctions:Array=['record'];

		private var serviceDic:Dictionary;
		private var refreshTimer:Timer;

		public var contactInfo:String='请电话联系 ';
		private var nowOffset:Number=0;

		public function API()
		{
//			var so:SharedObject=SharedObject.getLocal('yp');
//			so.clear();
//			so.flush();
//			var file:File=File.applicationStorageDirectory.resolvePath('log');
//			trace('log dir:' + file.nativePath);
			serviceDic=new Dictionary();
			QNService.HOST='http://yfcdn.qiniudn.com/';
//			QNService.token='xyGeW-ThOyxd7OIkwVKoD4tHZmX0K0cYJ6g1kq4J:ipn0o9U2O5eifFaiHhKpfZvqS8Q=:eyJzY29wZSI6InlmY2RuIiwiZGVhZGxpbmUiOjE0MDI1OTUxMjJ9';
			if (Capabilities.isDebugger)
				ServiceBase.HOST='http://localhost:18080/api';
			else
				ServiceBase.HOST=isTest ? 'http://t.yuefu.com/api' : 'http://m.yuefu.com/api';
			if (local)
			{
				online=false;
				FileManager.savedDir=File.applicationDirectory.resolvePath('local').nativePath + '/';
			}
			else
			{
				try
				{
					var u:URLRequest=new URLRequest('http://m.yuefu.com/log/token');
					var ul:URLLoader=new URLLoader();
					ul.addEventListener(Event.COMPLETE, function(e:Event):void
					{
						var o:Object=JSON.parse(ul.data);
						QNService.token=o.uptoken;
					});
					ul.load(u);

					var u2:URLRequest=new URLRequest('http://m.yuefu.com/now');
					var ul2:URLLoader=new URLLoader();
					ul2.addEventListener(Event.COMPLETE, function(e:Event):void
					{
						var date:Date=NodeUtil.getLocalDate(ul2.data);
						nowOffset=date.getTime() - now.getTime();
						trace('Now Offset:' + nowOffset);
//						var o:Object=JSON.parse(ul2.data);
//						QNService.token=o.uptoken;
					});
					ul2.load(u2);
				}
				catch (error:Error)
				{
					trace('get token error');
				}
			}
			refreshTimer=new Timer(1000);
			refreshTimer.addEventListener(TimerEvent.TIMER, refreshHandler);
		}

		public function get now():Date
		{
			return isTest ? new Date() : new Date(new Date().getTime() + nowOffset);
		}

		protected function refreshHandler(event:TimerEvent):void
		{
			if (refreshTimer.currentCount % 60 == 0 && !local)
			{
				getSB('/refresh/2', 'GET').call(function(vo:ResultVO):void
				{
					if (vo.status && !pv)
					{
						var menus:Array=FileManager.readFile('menus.yp') as Array;
						var brosChanged:Boolean;
						if (compareBros(vo.results.bros))
						{
							brosChanged=true;
							if (vo.results.bros)
								FileManager.saveFile('bros.yp', vo.results.bros)
							initBroadcasts();
						}
						if (compareMenus(menus, vo.results.menus as Array))
						{
							initMenu();
						}
						else if (brosChanged)
						{
							pv=new PrepareWindow();
							pv.addEventListener('loaded', function(e:Event):void
							{
								pv=null;
							});
							if (broadcasts)
								pv.broadcasts=broadcasts.concat();
							PopupBoxManager.popup(pv);
						}
						if (vo.results.message)
						{
							handleMessage(vo.results.message._id, 1);
							var mw:MessageWindow=new MessageWindow();
							mw.message=vo.results.message;
							mw.title=vo.results.message.title;
							mw.open();
						}
					}
				});
			}
		}

		/**
		 * 处理消息
		 * @param messageID
		 * @param status
		 */
		public function handleMessage(messageID:String, status:int, callback:Function=null):void
		{
			getSB('message/update', 'GET').call(function(vo:ResultVO):void
			{
				if (!vo.status)
				{
					appendLog(vo.errorResult);
					TweenLite.killDelayedCallsTo(handleMessage);
					TweenLite.delayedCall(3, handleMessage, [messageID, status, callback]);
				}
				else if (callback != null)
				{
					callback();
				}
			}, {_id: messageID, received: status == 1});
		}

		public function recordDM(ivo:InsertVO):void
		{
			var arr:Array=dmLogSO.data.plaied;
			if (!arr)
			{
				arr=[];
				dmLogSO.data.plaied=arr;
			}
			arr.push({id: ivo._id, plaied: now.toUTCString()});
			dmLogSO.flush();
			getSB('dm/record', 'GET').call(function(vo:ResultVO):void
			{
				if (vo.status)
					dmLogSO.clear();
				else
					appendLog(vo.errorResult);
			}, {dms: JSON.stringify(arr)});
		}

		public function appendLog(log:String):void
		{
			var path:String='log/' + DateUtil.getYMD(now, 0, '_') + '.log';
			var file:File;
			if (path.charAt(0) == '/')
				path=path.substr(1);
			var fs:FileStream=new FileStream();
			createDirectory(path);
			file=File.applicationStorageDirectory.resolvePath(path);
			try
			{
				fs.open(file, FileMode.APPEND);
				fs.writeUTFBytes(DateUtil.getDateString(0, 0, true) + log + '\n');
				fs.close();
			}
			catch (error:Error)
			{
				trace('save file error', error);
			}

		}

		private function createDirectory(path:String):void
		{
			var arr:Array=path.match(new RegExp('.*(?=/)'));
			if (!arr || !arr.length)
				return;
			var directory:String=arr[0]; //a
			var file:Object=File.applicationStorageDirectory.resolvePath(directory);
			if (!file.exists)
			{
				trace("FileCache - Directory not found, create it !");
				file.createDirectory();
			}
		}

		private function compareBros(arr:Array):Boolean
		{
			var changed:Boolean;
			var bs:Array=FileManager.readFile('bros.yp') as Array;
			if (bs)
			{
				if (bs.length != arr.length)
				{
					changed=true;
				}
				else
				{
					for each (var o1:Object in bs)
					{
						var exists:Boolean=false;
						for each (var o2:Object in arr)
						{
							if (o1._id == o2._id && o1.name == o2.name)
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

		private var dmChanged:Boolean;

		private function compareMenus(menus:Array, newMenus:Array):Boolean
		{
			var changed:Boolean=false;
			if (!newMenus)
				return false;
			if (!menus || menus.length != newMenus.length)
			{
				FileManager.saveFile('menus.yp', newMenus);
				changed=true;
				trace('menu changed');
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
						trace('menu changed');
						FileManager.saveFile('menus.yp', newMenus);
						break;
					}
				}
			}
			return changed;
		}

		public function getMenuList():void
		{
			trace('saved_dir', FileManager.savedDir);
			if (menu || !FileManager.savedDir)
				return;
			try
			{
				var menus:Array=FileManager.readFile('menus.yp') as Array;

				if (online && !local)
				{
					getSB('menu/list/2', 'GET').call(function(vo:ResultVO):void
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
								if (!menus || !menus.length)
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
			catch (e:Event)
			{
				PAlert.show(e);
			}
		}

		[Bindable]
		public var songs:Array;

		public function getRandomSong():SongVO
		{
			var vo:SongVO;
			var arr:Array=[];
			if (!isCurrentTimeLoop)
			{
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
			}
			else
			{
				arr=songs;
				vo=arr[Math.floor(Math.random() * arr.length)];
			}
			return vo;
		}

		[Bindable]
		public var broadcasts:Array;

		private function dateValidate(begin:Object, end:Object):Boolean
		{
			if (!(begin is Date))
				begin=NodeUtil.getLocalDate(begin as String);
			if (!(end is Date))
				end=NodeUtil.getLocalDate(end as String);
			var n:Date=now;
			n=new Date(n.getFullYear(), n.getMonth(), n.getDate())
			return n.getTime() >= begin.getTime() && n.getTime() <= end.getTime();
		}

		private function initMenu():void
		{
			var menus:Array=FileManager.readFile('menus.yp') as Array;
			if (menus && menus.length)
			{
				var i:int;
				var listMenu:Object;
				var dmMenus:Array=[];
				var o:Object;
				var n:Date=now;
				n=new Date(n.getFullYear(), n.getMonth(), n.getDate())
				for (i=0; i < menus.length; i++)
				{
					o=menus[i];
					o.end_date=NodeUtil.getLocalDate(o.end_date);
					o.begin_date=NodeUtil.getLocalDate(o.begin_date);
					if (o.type == 1 && n.getTime() >= o.begin_date.getTime() && n.getTime() <= o.end_date.getTime())
					{
						listMenu=o;
						break;
					}
				}
				for (i=0; i < menus.length; i++)
				{
					o=menus[i];
					if (!(o.end_date is Date))
						o.end_date=NodeUtil.getLocalDate(o.end_date);
					if (!(o.begin_date is Date))
						o.begin_date=NodeUtil.getLocalDate(o.begin_date);
					if (o.type == 2 && n.getTime() >= o.begin_date.getTime() && n.getTime() <= o.end_date.getTime())
					{
						dmMenus.push(o);
					}
				}

				if (!listMenu)
				{
					noPlayList();
					return;
				}
				else
				{
					o=listMenu;
				}

				if (n.getTime() <= o.end_date.getTime())
				{
					var songMenu:Object;
					var dmMenuO:Object;
					var dmCount:int;
					if (dmMenus.length)
					{
						for each (var dmm:Object in dmMenus)
						{
							LoadManager.instance.loadText(QNService.HOST + dmm._id + '.json', function(data:String):void
							{
								dmCount++;
								var o:Object=JSON.parse(data);
								if (!dmMenuO)
									dmMenuO=o
								else
									dmMenuO.dm_list=dmMenuO.dm_list.concat(o.dm_list);
								if (songMenu && dmCount == dmMenus.length)
									parseMenu(songMenu, dmMenuO);
							}, dmm._id + '.json', online);
						}
					}
					LoadManager.instance.loadText(QNService.HOST + o._id + '.json', function(data:String):void
					{
						songMenu=JSON.parse(data);
						if (dmMenus.length)
						{
							if (dmMenuO && dmCount == dmMenus.length)
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


			if (refreshTimer && !refreshTimer.running)
				refreshTimer.start();
		}

		public var times:Array=[];

		public function get isCurrentTimeLoop():Boolean
		{
			var b:Boolean;
			for each (var o:Object in times)
			{
				if (o.begin.getTime() < now.getTime() && o.end.getTime() > now.getTime())
				{
					b=o.loop;
					break;
				}
			}
			return b;
		}

		public var dmMenu:Object;

		public function parseMenu(songMenu:Object, dmMenu:Object, onlyParse:Boolean=false):Object
		{
			var o:Object=songMenu;
			if (o)
			{
				o.end_date=NodeUtil.getLocalDate(o.end_date);
				o.begin_date=NodeUtil.getLocalDate(o.begin_date);
			}
			var songs:Array=[];
//			dms=[];
			var songDMDic:Dictionary=new Dictionary();
//			this.dmMenu=dmMenu;
			if (dmMenu && dmMenu.dm_list)
			{
				var a:Array=[];
				for each (var dm:Object in dmMenu.dm_list)
				{
					if (dm.day)
					{
						var day:String=now.getDay() + '';
						if (dm.day.indexOf(day) == -1)
							continue;
					}
					var ivo:InsertVO=new InsertVO();
					ivo.size=dm.size;
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

			if (o && o.list)
			{
				var dms:Array=[];
				if (dmMenu && dmMenu.dm_list)
					dms=dmMenu.dm_list.concat();
				var playTime:Date;
				var i:int;
				for (i=0; i < o.list.length; i++)
				{
					var oo:Object=o.list[i]
					oo.begin=DateUtil.getDateByHHMMSS(oo.begin);
					oo.end=DateUtil.getDateByHHMMSS(oo.end);
					if (!playingSong && dateValidate(o.begin_date, o.end_date))
						times.push({begin: oo.begin, end: oo.end, loop: Boolean(oo.loop)});
					playTime=DateUtil.clone(oo.begin);
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
							song.size=s.size;
							song._id=s._id;
							song.url=QNService.HOST + s.url + '?p/1/avthumb/mp3/ab/' + o.quality + 'k';
//							song.url=QNService.HOST + s.url;
							//										song.cover = QNService.getQNThumbnail(s.cover, 200, 200);
							song.name=s.name
							song.duration=s.duration;
							arr.push(song);
							songs.push(song);
							duration=s.duration;
							if (dmMenu && dmMenu.dm_list && !oo.loop)
							{
								var t1:Number=playTime.getTime();
								playTime.seconds+=s.duration;
								var t2:Number=playTime.getTime();
								var dmarr:Array=[];
								for each (var dmivo:InsertVO in dms)
								{
									var t3:Number=dmivo.playTime.getTime();
									if (t1 <= t3 && t3 <= t2)
									{
										dmarr.push(dmivo);
										songs.push(dmivo);
										dms.splice(dms.indexOf(dmivo), 1);
										break;
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
				trace(dms.length);
				o.list=CloneUtil.convertArrayObjects(o.list, TimeVO);
			}
			if (!onlyParse)
			{
				if (!playingSong && o && dateValidate(o.begin_date, o.end_date))
				{
					this.menu=CloneUtil.convertObject(o, MenuVO);
					this.dmMenu=dmMenu;
					this.songs=songs;
					this.songDMDic=songDMDic;
				}
				else if (dmMenu && dateValidate(dmMenu.begin_date, dmMenu.end_date))
				{
					this.dmMenu=dmMenu;
					this.songs=songs;
					this.songDMDic=songDMDic;
					dmChanged=true;
				}
				if (!this.menu)
				{
					noPlayList();
					return {};
				}
				if (playingSong)
					initBroadcasts();
				toPrepare(o, dmMenu);
			}
			return {songs: songs, dmMenu: dmMenu};
		}

		private function toPrepare(menu:Object, dmMenu:Object):void
		{
			if (playingSong && !dmChanged)
			{
				if (menu && dmMenu)
				{
					if (hasCached(menu._id) && hasCached(dmMenu._id))
						return;
				}
				else if (menu && hasCached(menu._id))
					return;
				else if (dmMenu && hasCached(dmMenu._id))
					return;
			}

			pv=new PrepareWindow();
			var label:String;
			if (menu)
			{
				label=menu.name;
				pv.menuID=menu._id;
			}
			if (dmMenu)
			{
				label+=' ' + dmMenu.name;
				pv.dmMenu=dmMenu._id;
			}
			pv.addEventListener('loaded', function(e:ODataEvent):void
			{
				if (e.data)
				{
					var so:SharedObject=updateLogSO;
					so.data.data=e.data;
					so.flush();
					uploadUpdateLog();
				}
				else
				{
					checkMenuToUpdate();
				}
				if (!playingSong || dmChanged)
				{
					initBroadcasts();
					dmChanged=false;
					dispatchEvent(new Event('PLAY'));
				}
				pv=null;
			});
			if (dmMenu && dmMenu.dm_list)
			{
				pv.dms=dmMenu.dm_list;
				pv.dmMenu=dmMenu._id;
			}
			if (songs)
				pv.songs=songs.concat();
			if (broadcasts)
				pv.broadcasts=broadcasts.concat();
			pv.label=label;
			pv.open();
//			PopupBoxManager.popup(pv);
		}

		private function get dmLogSO():SharedObject
		{
			return SharedObject.getLocal('dmLog');
		}

		private function get updateLogSO():SharedObject
		{
			return SharedObject.getLocal('updateLog');
		}

		private function get cachedSO():SharedObject
		{
			return SharedObject.getLocal('cached');
		}

		public function hasCached(id:String):Boolean
		{
			var b:Boolean;
			var cached:SharedObject=cachedSO;
			var arr:Array=cached.data.menus;
			if (arr)
			{
				for each (var cachedID:String in arr)
				{
					if (id == cachedID)
					{
						b=true;
						break;
					}
				}
			}
			return b;
		}

		private function uploadUpdateLog():void
		{
			var so:SharedObject=updateLogSO;
			var cached:SharedObject=cachedSO;
			var log:Object=so.data.data;
			if (log)
			{
				getSB('/update/log').call(function(vo:ResultVO):void
				{
					if (vo.status)
					{
						so.clear();
						if (!cached.data.menus)
							cached.data.menus=[];
						var menus:Array=cached.data.menus;
						if (log.songMenu && menus.indexOf(log.songMenu) == -1)
							menus.push(log.songMenu);
						if (log.dmMenu && menus.indexOf(log.dmMenu) == -1)
							menus.push(log.dmMenu);
						cached.flush();
						checkMenuToUpdate();
					}
					else
					{
						TweenLite.killDelayedCallsTo(uploadUpdateLog);
						TweenLite.delayedCall(60, uploadUpdateLog);
					}
				}, log);
			}
		}

		private function checkMenuToUpdate():void
		{
			var menus:Array=FileManager.readFile('menus.yp') as Array;
			var cached:Array=cachedSO.data.menus;
			for each (var m:Object in menus)
			{
				if (cached.indexOf(m._id) == -1)
				{
					if (m.type == 1)
					{
						parseMenu(m, null);
					}
					else
					{
						parseMenu(null, m);
					}
					break;
				}
			}
		}

		public var songDMDic:Dictionary;

//		public var dms:Array;

		private function noPlayList():void
		{
			PAlert.show('您的播放歌单尚未准备完毕，请联系客服进行添加并保持网络连接', '初始化失败', null, function():void
			{
				online=true
				getMenuList();
			}, PAlert.CONFIRM, '再试一次', '', true);
		}

		public function initBroadcasts():void
		{
			var bs:Array=FileManager.readFile('bros.yp') as Array;
			if (bs)
			{
				for each (var o:Object in bs)
				{
					o.playTime=DateUtil.getDateByHHMMSS(o.playTime);
					if (o.url.indexOf('http') == -1)
						o.url=QNService.HOST + o.url;
				}
			}
			else
			{
				return
			}
			if (enableFunctions.indexOf('record') != -1)
			{
				var so:SharedObject=SharedObject.getLocal('yp');
				var records:Array=so.data.records;
				if (!records)
				{
					records=[]
					records.push({name: '定制广播1', type: 1});
					records.push({name: '定制广播2', type: 1});
					records.push({name: '定制广播3', type: 1});
				}
				bs=bs.concat(records);
			}
			broadcasts=CloneUtil.convertArrayObjects(bs, InsertVO);
			var arr:Array=[];
			if (broadcasts)
			{
				for each (var oo:Object in broadcasts)
				{
					if (oo && oo != 'null')
						arr.push(oo);
				}
			}
			broadcasts=arr;
			dispatchEvent(new Event('bros'));
		}

		[Bindable]
		public var playingIndex:int;

		public function login(username:String, password:String, callback:Function):void
		{
			username=username.replace(' ', '');
			var f:File;
			getSB('user/login').call(function(vo:ResultVO):void
			{
				var so:SharedObject=SharedObject.getLocal('yp');
				var cd:String=so.data.cacheDir;
				var exists:Boolean;
				try
				{
					if (cd)
					{
						cd=cd.replace(/\\/g, '/');
						f=new File(cd);
						exists=f.isDirectory;
					}
				}
				catch (error:Error)
				{
				}
				if (vo.status)
				{
					broadcasts=vo.results.broadcasts;
					ServiceBase.id=vo.results.id + '';
					if (cd && exists)
					{
						FileManager.savedDir=so.data.cacheDir;
						FileManager.saveFile('bros.yp', broadcasts);
						getMenuList();
					}
					checkLog();
					uploadUpdateLog();
					test();
				}
				else if (cd)
				{
					FileManager.savedDir=cd;
				}
				if (!cd || !exists)
				{
					if (vo.status)
					{
						var sv:SelectCacheView=new SelectCacheView();
						PopupBoxManager.popup(sv, function():void
						{
							so=SharedObject.getLocal('yp');
							FileManager.savedDir=so.data.cacheDir;
							if (broadcasts)
								FileManager.saveFile('bros.yp', broadcasts);
							getMenuList();
						});
					}
				}
				callback(vo);
			}, {username: username, password: password});
		}

		private function test():void
		{
//			var vo:InsertVO=new InsertVO();
//			vo._id='5399c4dd03aba48d3896c498';
//			recordDM(vo);
		}

		private function checkLog():void
		{
			var file:File=File.applicationStorageDirectory.resolvePath('log');
			if (file.exists && file.isDirectory)
			{
				var files:Array=file.getDirectoryListing();
				if (files.length)
				{
					var f:File=files.shift() as File;
					var upName:String=ServiceBase.id + '-' + DateUtil.getHMS(now) + '-' + f.name;
					QNService.instance.upload(f, function(r:Object):void
					{
						var re:ResultVO=r as ResultVO;
						if (re && re.status)
							f.deleteFile();
					}, {key: upName});
				}
			}
		}

		[Bindable]
		public var updatable:Boolean;

		public var updater:NativeApplicationUpdater;
		public var playingSong:SongVO;
		private var pv:PrepareWindow;

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

