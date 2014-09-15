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
	import com.pamakids.utils.URLUtil;
	import com.plter.air.windows.utils.NativeCommand;
	import com.plter.air.windows.utils.ShowCmdWindow;
	import com.youli.nativeApplicationUpdater.NativeApplicationUpdater;

	import flash.desktop.NativeApplication;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;

	import mx.formatters.DateFormatter;
	import mx.utils.UIDUtil;

	import models.InsertVO;
	import models.LogVO;
	import models.MenuVO;
	import models.SongVO;
	import models.TimeVO;

	import views.Main;
	import views.MessageWindow;
	import views.SelectCacheView;
	import views.windows.PrepareWindow;

	public class API extends Singleton
	{
		[Bindable]
		public var local:Boolean=false;
		public var online:Boolean=true;
		public var isTest:Boolean=false;
		public var isTool:Boolean=false; //是否作为下载mp3工具使用
		[Bindable]
		public var showTrace:Boolean=false; //是否显示trace信息面板

		public var enableFunctions:Array=['record'];
//		public var enableFunctions:Array=['record', 'insert'];

		private var serviceDic:Dictionary;
		private var refreshTimer:Timer;

		public var contactInfo:String='客服电话1：010-51244052\n客服电话2：010-58699501\nQQ1：王萍 99651674\nQQ2：杨丹丹 1690762409\nQQ3：段颖 3779317';
		private var nowOffset:Number=0;
		private var config:Object;
		private var autoUpadte:Boolean;
		public var serial_number:String;
		private var day:Number;

		public function API()
		{
			var o:Object=FileManager.readFile('config.json', true, true);
			o=JSON.parse(o + '');
			isTest=o.test;
			local=o.local;
			autoUpadte=o.auto_update;
			showTrace=o.trace;
			config=o;

			if (isTest)
				enableFunctions.push('insert');

			var so:SharedObject;
			so=SharedObject.getLocal('sn');
			if (!so.data.sn)
			{
				so.data.sn=UIDUtil.createUID();
				so.flush();
			}
			serial_number=so.data.sn;
			so=SharedObject.getLocal('version');
			if (!so.data.version)
				if (o.version)
					so.data.version=o.version;
				else
					so.data.version='1.6.0';
			so.flush();
			version=so.data.version;
			so=SharedObject.getLocal('yp');
			if (so.data.id)
				ServiceBase.id=so.data.id;
//			var so:SharedObject=SharedObject.getLocal('yp');
//			so.clear();
//			so.flush();
//			var file:File=File.applicationStorageDirectory.resolvePath('log');
//			trace('log dir:' + file.nativePath);
			serviceDic=new Dictionary();
			QNService.HOST='http://yfcdn.qiniudn.com/';
//			QNService.token='xyGeW-ThOyxd7OIkwVKoD4tHZmX0K0cYJ6g1kq4J:ipn0o9U2O5eifFaiHhKpfZvqS8Q=:eyJzY29wZSI6InlmY2RuIiwiZGVhZGxpbmUiOjE0MDI1OTUxMjJ9';
			var b:Boolean=o.debug == null ? Capabilities.isDebugger : o.debug;
			if (b)
			{
				var file:File=File.applicationStorageDirectory.resolvePath('log');
				if (file.exists)
					trace('log:' + FileManager.readFile(file.nativePath, false, true));
				ServiceBase.HOST='http://localhost:18080/api';
			}
			else
				ServiceBase.HOST=isTest ? 'http://t.yuefu.com/api' : 'http://m.yuefu.com/api';
			so=SharedObject.getLocal('yp');
			if (local)
			{
				so.data.username=o.username;
				so.flush();
				online=false;
				FileManager.savedDir=File.applicationDirectory.resolvePath('local').nativePath + '/';
			}
			else
			{
				getUploadToken();
				getNowTime();
			}
			if (local || enabledInsert())
			{
				if (!so.data.localDMS)
				{
					var dmm:MenuVO=new MenuVO();
					dmm.type=MenuVO.DM;
					dmm.begin_date=new Date(now.fullYear, now.getMonth(), now.getDate(), 0, 0, 0, 0);
					dmm.end_date=new Date(now.fullYear, now.getMonth(), now.getDate(), 0, 0, 0, 0);
					dmm.name='默认列表';
					so.data.localDMS=[dmm];
					so.flush();
				}
			}
			setYPData('startup', new Date().getTime());
			setYPData('refreshTime', new Date().getTime());
			refreshTimer=new Timer(1000);
			refreshTimer.addEventListener(TimerEvent.TIMER, refreshHandler);
			startAtLogin();
		}

		private function enabledInsert():Boolean
		{
			return enableFunctions.indexOf('insert') != -1;
		}

		public function getLocalDMS():Array
		{
			var so:SharedObject=SharedObject.getLocal('yp');
			return CloneUtil.convertArrayObjects(so.data.localDMS, MenuVO);
		}

		public function updateLocalDMS(arr:Array):void
		{
			var so:SharedObject=SharedObject.getLocal('yp');
			so.data.localDMS=arr;
			so.flush();
		}

		public function initUncaughtErrorListener(loaderInfo:Object):void
		{
			loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, function(e:UncaughtErrorEvent):void
			{
				if (e.error is Error)
				{
					var stack:String=Error(e.error).getStackTrace();
					appendLog(Error(e.error).message + ((stack != null) ? "\n" + stack : ""));
				}
				else if (e.error is ErrorEvent)
					appendLog(ErrorEvent(e.error).text);
				else
					appendLog(e.error.toString());
			});
		}

		private var needReboot:Boolean;

		public function downloadUpdate(callback:Function=null):void
		{
			LoadManager.instance.load('http://yfcdn.qiniudn.com/file/' + newVersion + '/' + config.swf, function(b:ByteArray):void
			{
				if (b && b.length)
				{
					try
					{
						var f:File=File.applicationDirectory.resolvePath(config.swf);
						f=new File(f.nativePath);
						var fs:FileStream=new FileStream();
						fs.open(f, FileMode.WRITE);
						fs.writeBytes(b);
						fs.close();
						var so:SharedObject=SharedObject.getLocal('version');
						so.data.version=newVersion;
						so.flush();
						version=newVersion
						if (autoUpadte)
						{
							recordLog(new LogVO(LogVO.AUTO_UPDATE_END, newVersion, '版本自动更新成功'));
							if (!playingSong)
								reboot();
							else
								needReboot=true;
						}
						else
						{
							PAlert.show(newVersion + '版本更新完毕，重启后生效。\n如果软件正在播放建议您先暂不重启，下次开启软件的时候也会自动生效', '提示', null, function(value:String):void
							{
								reboot();
							}, PAlert.YESNO, '重启播放器', '暂时不重启');
						}
					}
					catch (error:Error)
					{
						PAlert.show(error.message);
					}
				}
				else
				{
					if (autoUpadte)
					{
						recordLog(new LogVO(LogVO.WARNING, newVersion, '版本自动更新失败'));
						return;
					}
					if (callback != null)
						callback(0)
					PAlert.show('更新失败，请检查网络连接');
				}
			}, 'update/' + newVersion + '.swf', null, callback, false, 'binary', function(e:Event, par:Object):void
			{
				if (autoUpadte)
				{
					recordLog(new LogVO(LogVO.WARNING, newVersion, '版本自动更新失败'));
					return;
				}
				if (callback != null)
					callback(0)
				PAlert.show('更新失败，请检查网络连接');
			});
		}

		private function startAtLogin():void
		{
//			if (Capabilities.os.indexOf('Windows') == -1 || Capabilities.isDebugger)
//				return;
//			var so:SharedObject=SharedObject.getLocal('yp');
//			if (!so.data.settedStartAtLogin)
//			{
//				var rg:RegCommand=new RegCommand();
//				rg.addAutoRunWithName('YFPlayer', File.applicationDirectory.resolvePath("乐播.exe").nativePath);
//				so.data.settedStartAtLogin=true;
//				so.flush();
//			}
		}

		private function get formatedNow():String
		{
			var df:DateFormatter=new DateFormatter('YY-MM-DD HH:MM:SS');
			return df.format(now);
		}

		public function reboot(forUpdate:Boolean=true):void
		{
			var logvo:LogVO;
			if (forUpdate)
				logvo=new LogVO(LogVO.REBOOT_AUTO_UPDATE, formatedNow, '自动重启为更新：' + newVersion)
			else
				logvo=new LogVO(LogVO.REBOOT_BY_COMMAND, formatedNow, '通过命令自动重启')
			recordLog(logvo, function():void
			{
				appendLog('软件重启');
				var n:NativeCommand=new NativeCommand();
				var args:Vector.<String>=new Vector.<String>;
				args.push(File.applicationDirectory.resolvePath("乐播.exe").nativePath);
				n.runCmd(args, ShowCmdWindow.HIDE, 1000);
				NativeApplication.nativeApplication.exit();
			});
		}


		private function getNowTime():void
		{
			var u:URLRequest=new URLRequest('http://m.yuefu.com/now');
			var ul:URLLoader=new URLLoader();
			ul.addEventListener(Event.COMPLETE, function(e:Event):void
			{
				if (ul.data)
				{
					var date:Date=NodeUtil.getLocalDate(ul.data);
					nowOffset=date.getTime() - now.getTime();
					setYPData('startup', now.getTime());
					setYPData('refreshTime', now.getTime());
					day=now.day;
				}
				trace('Now Offset:' + nowOffset);
			});
			ul.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void
			{
				appendLog('GetNow Error' + e.toString());
				TweenLite.killDelayedCallsTo(getNowTime);
				TweenLite.delayedCall(60, getNowTime);
			});
			ul.addEventListener(HTTPStatusEvent.HTTP_STATUS, function(e:HTTPStatusEvent):void
			{
				if (e.status && e.status != 200)
				{
					TweenLite.killDelayedCallsTo(getNowTime);
					TweenLite.delayedCall(60, getNowTime);
					appendLog('GetNow Error' + e.toString());
				}
			});
			ul.load(u);
		}

		private function getUploadToken():void
		{
			var tokenURL:String=isTest ? 'http://t.yuefu.com/log/token' : 'http://m.yuefu.com/log/token';
			var u:URLRequest=new URLRequest(tokenURL);
			var ul:URLLoader=new URLLoader();
			ul.addEventListener(Event.COMPLETE, function(e:Event):void
			{
				if (ul.data)
				{
					var o:Object=JSON.parse(ul.data);
					QNService.token=o.uptoken;
					checkLog();
				}
			});
			ul.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void
			{
				appendLog('GetUploadToken Error' + e.toString());
				TweenLite.killDelayedCallsTo(getUploadToken);
				TweenLite.delayedCall(60, getUploadToken);
			});
			ul.addEventListener(HTTPStatusEvent.HTTP_STATUS, function(e:HTTPStatusEvent):void
			{
				if (e.status && e.status != 200)
				{
					TweenLite.killDelayedCallsTo(getUploadToken);
					TweenLite.delayedCall(60, getUploadToken);
					appendLog('GetUploadToken Error' + e.toString());
				}
			});
			ul.load(u);
		}

		public function get now():Date
		{
			return isTest ? new Date() : new Date(new Date().getTime() + nowOffset);
		}

		protected function refreshHandler(event:TimerEvent):void
		{
			if (local)
				return;
			if (refreshTimer.currentCount % 60 == 0)
			{
				refreshData();
				var refresh:Number=getYPData('refreshTime') as Number;
				if (now.getTime() - refresh >= 24 * 60 * 60 * 1000)
				{
					checkLog();
					setYPData('refreshTime', now.getTime());
				}
				if (!checkPlayingValid())
					initMenu();

				checkLogin();
			}
			if (autoUpadte && refreshTimer.currentCount % 3600 == 0)
			{
				if (needReboot && !playingSong)
					reboot(rebootByCommand);
				else
					checkUpdate();
			}
		}

		private function checkLogin():void
		{
			if (local)
				return;
			if (!ServiceBase.id)
			{
				var so:SharedObject=SharedObject.getLocal('yp');
				getSB('user/login').call(function(vo:ResultVO):void
				{
					if (vo.status)
						ServiceBase.id=vo.results.id + '';
					else
						appendLog('LoginError:' + so.data.username + '-' + so.data.password + '-' + vo.errorResult);
				}, {username: so.data.username, password: so.data.password});
			}
		}

		public var main:Main;

		private function refreshData():void
		{
			var pn:String;
			if (!playingInfo)
			{
				if (playingSong)
					pn='正在播放歌曲：' + playingSong.name + ' 来自歌单：' + menu.name;
				else
					pn=main.time;
			}
			else
			{
				pn=playingInfo;
			}

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
					var daychanged:Boolean;
					if (day != now.day && !initializing && !playingSong)
					{
						trace('Day Changed');
						daychanged=true;
						day=now.day;
					}
					if (compareMenus(menus, vo.results.menus as Array) || daychanged)
					{
						var playingValid:Boolean=checkPlayingValid();
						if (daychanged || !playingValid)
						{
							menu=null;
							songs=null;
							songDMDic=null;
						}
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
						pv.open();
					}
					if (vo.results.message)
					{
						handleMessage(vo.results.message._id, 1);
						var mw:MessageWindow=new MessageWindow();
						mw.message=vo.results.message;
						mw.title=vo.results.message.title;
						mw.open();
					}
					if (vo.results.reboot)
						reboot(false);
					if (vo.results.update)
						checkUpdate();
				}
				else
				{
					appendLog('RefreshFailed：' + vo.errorResult);
				}
			}, {startup: getYPData('startup'), version: version, playing: pn, serial_number: serial_number});
		}

		private var rebootByCommand:Boolean;

		public var playingInfo:String;

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

		public function recordLog(o:LogVO, callbck:Function=null):void
		{
			if (local || Capabilities.isDebugger)
			{
				if (callbck != null)
					callbck();
				return;
			}
			var so:SharedObject=SharedObject.getLocal('log');
			var logs:Array=so.data.logs;
			if (!logs)
				logs=[];
			if (o)
			{
				o.created_at=now.getTime();
				logs.push(o);
				so.data.logs=logs;
				so.flush();
			}
			getSB('log/record').call(function(vo:ResultVO):void
			{
				if (vo.status)
					so.clear();
				else
					appendLog('RecordLogError:' + vo.errorResult);
				if (callbck != null)
					callbck();
			}, {logs: JSON.stringify(logs), version: version, serial_number: serial_number});
		}

		public function recordDM(ivo:InsertVO):void
		{
			if (local)
				return;
			var arr:Array=dmLogSO.data.plaied;
			if (!arr)
			{
				arr=[];
				dmLogSO.data.plaied=arr;
			}
			arr.push({id: ivo._id, plaied: now.toUTCString()});
			dmLogSO.flush();
			getSB('dm/record').call(function(vo:ResultVO):void
			{
				if (vo.status)
					dmLogSO.clear();
				else
					appendLog('RecordDM Error:' + vo.errorResult);
			}, {dms: JSON.stringify(arr), version: version, serial_number: serial_number});
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
			progress='连接云系统成功，开始获取新内容';
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

		public function getCurrentTimeSongs():Array
		{
			var vo:SongVO;
			var arr:Array=[];
			for each (var t:TimeVO in menu.list)
			{
				if (t.begin.getTime() < now.getTime() && t.end.getTime() > now.getTime())
				{
					for each (var s:SongVO in t.songs)
					{
						if (s.allow_circle || t.loop)
							arr.push(s);
					}
					break;
				}
			}
			return arr;
		}

		public function getRandomSong(svo:SongVO):SongVO
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
					}
				}
			}
			else
			{
				arr=currentTime.songs;
			}
			if (arr.length)
			{
				if (!svo || arr.length == 1)
				{
					vo=arr[Math.floor(Math.random() * arr.length)];
				}
				else if (svo)
				{
					vo=arr[Math.floor(Math.random() * arr.length)];
					while (svo._id == vo._id)
					{
						vo=arr[Math.floor(Math.random() * arr.length)];
					}
				}
			}
			return vo;
		}

		[Bindable]
		public var broadcasts:Array;

		private function dateValidate(begin:Object, end:Object):Boolean
		{
			if (!begin || !end)
				return false;
			if (!(begin is Date))
				begin=NodeUtil.getLocalDate(begin as String);
			if (!(end is Date))
				end=NodeUtil.getLocalDate(end as String);
			var n:Date=now;
			n=new Date(n.getFullYear(), n.getMonth(), n.getDate())
			return n.getTime() >= begin.getTime() && n.getTime() <= end.getTime();
		}

		private function dayValidate(tags:Array):Boolean
		{
			var b:Boolean=true;
			if (tags && tags.length)
			{
				for (var i:int; i <= 6; i++)
				{
					if (tags.indexOf(i + '') != -1 && tags.indexOf(now.day + '') == -1)
					{
						b=false;
						break;
					}
				}
			}
			return b;
		}

		private function menuValid(menu:Object):Boolean
		{
			if (!menu || !menu.begin_date || !menu.end_date)
				return false;
			var n:Date=now;
			n=new Date(n.getFullYear(), n.getMonth(), n.getDate(), 0, 0, 0, 0);
			return n.getTime() >= menu.begin_date.getTime() && n.getTime() <= menu.end_date.getTime() && dayValidate(menu.tags);
		}

		private function checkPlayingValid():Boolean
		{
			var b:Boolean=true;
			var clearedSize:Number=0;
			var f:File;
			var clearInfo:String='';
			var o:Object;
			var so:SharedObject=cachedSO;
			var arr:Array=so.data.menus;
			if (menu && !menuValid(menu))
			{
				arr.splice(arr.indexOf(menu._id), 1);
				clearInfo+='清空了歌单：' + menu.name + ' ';
				if (songs && songs.length)
				{
					for each (o in songs)
					{
						if (o.url && o.url.indexOf('http') != -1)
						{
							f=new File(FileManager.savedDir + URLUtil.getCachePath(o.url));
							trace(f.name, f.size);
							clearedSize+=f.size;
							f.deleteFileAsync()
						}
					}
				}
				b=false;
				menu=null;
				songs=null;
				songDMDic=null;
			}
			if (dmMenus && dmMenus.length)
			{
				for each (var dm:Object in dmMenus)
				{
					if (!menuValid(dm))
					{
						b=false;
						arr.splice(arr.indexOf(dm._id), 1);
						clearInfo+='清空了DM：' + dm.name + ' ';
						if (dm.dm_list && dm.dm_list.length)
						{
							for each (o in dm.dm_list)
							{
								if (o.url && o.url.indexOf('http') != -1)
								{
									f=new File(FileManager.savedDir + URLUtil.getCachePath(o.url));
									clearedSize+=f.size;
									f.deleteFileAsync()
								}
							}
						}
					}
				}
			}
			if (!b)
			{
				so.data.menus=arr;
				so.flush();
				trace(clearedSize / 1024, clearInfo);
				recordLog(new LogVO(LogVO.CLEAR_CACHE, Math.round(clearedSize / 1024) + '', clearInfo));
			}
			return b;
		}

		private var dmMenus:Array;

		private var initializing:Boolean;

		public function initMenu():void
		{
			if (initializing)
				return;
			initializing=true;
			var menus:Array=FileManager.readFile('menus.yp') as Array;
			if (menus && menus.length)
			{
				var i:int;
				var listMenu:Object;
				dmMenus=[];
				var o:Object;
				var n:Date=now;
				n=new Date(n.getFullYear(), n.getMonth(), n.getDate())
				for (i=0; i < menus.length; i++)
				{
					o=menus[i];
					if (o.end_date && o.begin_date)
					{
						o.end_date=NodeUtil.getLocalDate(o.end_date);
						o.begin_date=NodeUtil.getLocalDate(o.begin_date);
						if (o.type == 1 && menuValid(o))
						{
							if (!listMenu)
								listMenu=o;
							else if (o.end_date.getTime() < listMenu.end_date.getTime())
								listMenu=o;
						}
					}
				}
				for (i=0; i < menus.length; i++)
				{
					o=menus[i];
					if (o.end_date && o.begin_date)
					{
						if (!(o.end_date is Date))
							o.end_date=NodeUtil.getLocalDate(o.end_date);
						if (!(o.begin_date is Date))
							o.begin_date=NodeUtil.getLocalDate(o.begin_date);
						if (o.type == 2 && menuValid(o))
						{
							dmMenus.push(o);
						}
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
		public var currentTime:Object;

		public function get isCurrentTimeLoop():Boolean
		{
			var b:Boolean;
			for each (var o:Object in menu.list)
			{
				if (o.begin.getTime() < now.getTime() && o.end.getTime() > now.getTime())
				{
					b=o.loop;
					currentTime=o;
					break;
				}
			}
			return b;
		}

		public var dmMenu:Object;
		public var updateForRecord:Boolean;

		private function getLocalInsertedMenu():MenuVO
		{
			var mvo:MenuVO;
			var arr:Array=getLocalDMS();
			var latest:Number;
			for each (var vo:MenuVO in arr)
			{
				trace(DateUtil.getYMD(vo.begin_date));
				trace(DateUtil.getYMD(vo.end_date));
				trace(DateUtil.getYMD(now));
				if (menuValid(vo))
				{
					if (!mvo && vo.dm_list && vo.dm_list.length)
						mvo=vo;
					else if (vo.dm_list && vo.dm_list.length)
						mvo.dm_list=mvo.dm_list.concat(vo.dm_list);
				}
			}
			return mvo;
		}

		public function checkLocalInsert(locals:Array, others:Array):Boolean
		{
			var dms:Array=others
			if (dms)
			{
				for each (var o:Object in dms)
				{
					var d1:Date;
					if (o.playTime is Date)
						d1=DateUtil.clone(o.playTime);
					else
						d1=DateUtil.getDateByHHMMSS(o.playTime);
					var v1:Number=d1.getTime();
					d1.seconds+=o.duration;
					var v2:Number=d1.getTime();
					for each (var o2:Object in locals)
					{
						var d:Date=DateUtil.getDateByHHMMSS(o2.playTime);
						var v3:Number=d.getTime();
						d.seconds+=o2.dm.duration;
						var v4:Number=d.getTime();
						if ((v3 >= v1 && v3 <= v2) || (v4 >= v1 && v4 <= v2))
						{
							d1.seconds-=o.duration;
							var op:String=d1.getHours() + ':' + d1.getMinutes();
							PAlert.show(o2.playTime + ' 插播的 ' + o2.dm.name + ' 同 ' + op + ' 插播的 ' + o.name + ' 时间冲突，请调整您的播放时间');
							return false;
						}
					}
				}
			}
			return true;
		}

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
			parseBroadcasts();
			var ivo:InsertVO;
			var a:Array=[];
			var localInsertedMenu:MenuVO;
			if (local || enabledInsert())
			{
				localInsertedMenu=getLocalInsertedMenu();
				if (!dmMenu)
					dmMenu=localInsertedMenu;
			}
			if (dmMenu && dmMenu.dm_list)
			{
				if (localInsertedMenu && dmMenu != localInsertedMenu)
					dmMenu.dm_list=dmMenu.dm_list.concat(localInsertedMenu.dm_list);
				for each (var dm:Object in dmMenu.dm_list)
				{
					if (dm.day)
					{
						var day:String=now.getDay() + '';
						if (dm.day.indexOf(day) == -1)
							continue;
					}
					ivo=new InsertVO();
					ivo._id=dm.dm._id;
					ivo.size=dm.size;
					ivo.name=dm.dm.name;
					ivo.duration=dm.dm.duration;
					if (dm.type)
						ivo.type=dm.type;
					if (dm.dm.url.indexOf('inserted') != -1)
						ivo.url=new File(FileManager.savedDir + dm.dm.url).url;
					else
						ivo.url=QNService.HOST + dm.dm.url;
					ivo.repeat=dm.repeat;
					ivo.playTime=DateUtil.getDateByHHMMSS(dm.playTime);
					ivo.interval=dm.interval;
					a.push(ivo);
				}
				dmMenu.dm_list=a;
			}

			if (needInsert() && insertBro)
			{
				if (!dmMenu)
				{
					dmMenu=new MenuVO();
					dmMenu.dm_list=a;
				}
				var bd:Date=DateUtil.getDateByHHMMSS('08:15:00');
				var ed:Date=DateUtil.getDateByHHMMSS('22:45:00');
				while (bd.getTime() < ed.getTime())
				{
					ivo=new InsertVO();
					ivo.type=InsertVO.AUTO_INSERT;
					ivo.name=insertBro.name;
					ivo.url=new File(FileManager.savedDir + insertBro.url).url;
					ivo.playTime=DateUtil.clone(bd);
					a.push(ivo);
					if (isLQ())
						bd.minutes+=15;
					else
						bd.minutes+=30;
				}
			}

			if (dmMenu && dmMenu)
			{
				dmMenu.dm_list.sort(function(a:Object, b:Object):int
				{
					if (a.playTime.getTime() < b.playTime.getTime())
						return -1
					else if (a.playTime.getTime() > b.playTime.getTime())
						return 1
					else
						return 0
				});
			}

			if (o && o.list)
			{
				var dms:Array=[];
				if (dmMenu && dmMenu.dm_list)
				{
					dms=dmMenu.dm_list.concat();
				}
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
						var songNum:int=0;
						for (var j:int=0; j < oo.songs.length; j++)
						{
							var s:Object=oo.songs[j];
							var song:SongVO=new SongVO();
							song.allow_circle=s.allow_circle;
							s=s.song;
							song.playTime=DateUtil.clone(playTime);
							if (playingSong && playingSong.playTime.getTime() == song.playTime.getTime())
								playingSong=song;
							song.size=s.size;
							song._id=s._id;
							if (isTool)
							{
								song.url=QNService.HOST + s.url;
								songNum++;
								song.name=songNum + '. ' + s.name + '.mp3'
							}
							else
							{
								username=SharedObject.getLocal('yp').data.username;
								if (username.indexOf('老娘舅') != -1)
									song.url=QNService.HOST + s.url;
								else
									song.url=QNService.HOST + s.url + '?p/1/avthumb/mp3/ab/' + o.quality + 'k';
								song.name=s.name
							}
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
										if (dmarr.indexOf(dmivo) == -1)
											dmarr.push(dmivo);
										if (songs.indexOf(dmivo) == -1)
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
				trace('DMS:' + dms.length);
				o.list=CloneUtil.convertArrayObjects(o.list, TimeVO);
			}
			if (!onlyParse)
			{
				if (!playingSong && o && dateValidate(o.begin_date, o.end_date))
				{
					if (!this.menu || this.menu._id == o._id)
					{
						this.menu=CloneUtil.convertObject(o, MenuVO);
						this.dmMenu=dmMenu;
						this.songs=songs;
						this.songDMDic=songDMDic;
						AA.say('UPDATE');
					}
					initializing=false;
				}
				else if (dmMenu && dateValidate(dmMenu.begin_date, dmMenu.end_date))
				{
					this.dmMenu=dmMenu;
					this.songs=songs;
					this.songDMDic=songDMDic;
					dmChanged=true;
					if (playingSong)
						playingIndex=songs.indexOf(playingSong);
					AA.say('UPDATE');
					initializing=false;
				}
				if (updateForRecord)
				{
					this.songs=songs;
					this.songDMDic=songDMDic;
					this.dmMenu=dmMenu;
					if (playingSong)
						playingIndex=songs.indexOf(playingSong);
					AA.say('UPDATE');
					initializing=false;
					updateForRecord=false;
				}
				else
				{
					if (!this.menu)
					{
						noPlayList();
						return {};
					}
					if (playingSong)
						initBroadcasts();
					if (local && !playingSong)
					{
						progress='';
						initializing=false;
						initBroadcasts();
						dmChanged=false;
						dispatchEvent(new Event('PLAY'));
						return {songs: songs, dmMenu: dmMenu};
					}
					toPrepare(o, dmMenu);
				}
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
					{
						initializing=false;
						return;
					}
				}
				else if (menu && hasCached(menu._id))
				{
					initializing=false;
					return;
				}
				else if (dmMenu && hasCached(dmMenu._id))
				{
					initializing=false;
					return;
				}
			}

			progress='开始初始化内容';

			pv=new PrepareWindow();
			var label:String;
			if (menu)
			{
				label=menu.name;
				pv.menuID=menu._id;
			}
			if (dmMenu && dmMenu._id)
			{
				label+=' ' + dmMenu.name;
				pv.dmMenu=dmMenu._id;
			}
			pv.addEventListener('loaded', function(e:ODataEvent):void
			{
				initializing=false;
				progress='';
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

//			if (Capabilities.isDebugger)
//			{
//				dispatchEvent(new Event('PLAY'));
//				initBroadcasts();
//			}
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
			if (local || Capabilities.isDebugger)
				return;
			var so:SharedObject=updateLogSO;
			var cached:SharedObject=cachedSO;
			var log:Object=so.data.data;
			if (log)
			{
				log.version=version;
				log.serial_number=serial_number;
				if (!cached.data.menus)
					cached.data.menus=[];
				var menus:Array=cached.data.menus;
				if (log.songMenu && menus.indexOf(log.songMenu) == -1)
					menus.push(log.songMenu);
				if (log.dmMenu && menus.indexOf(log.dmMenu) == -1)
					menus.push(log.dmMenu);
				cached.flush();
				getSB('/update/log').call(function(vo:ResultVO):void
				{
					if (vo.status)
					{
						so.clear();
						checkMenuToUpdate();
					}
					else
					{
						appendLog('UpdateLog Error:' + vo.errorResult);
						TweenLite.killDelayedCallsTo(uploadUpdateLog);
						TweenLite.delayedCall(600, uploadUpdateLog);
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
			initializing=false;
			PAlert.show('您的播放歌单尚未准备完毕，请联系客服进行添加并保持网络连接', '初始化失败', null, function():void
			{
				online=true
				getMenuList();
			}, PAlert.CONFIRM, '再试一次', '', true);
		}

		private function getYPData(key:String):Object
		{
			return SharedObject.getLocal('yp').data[key];
		}

		private function setYPData(key:String, value:Object):void
		{
			var so:SharedObject=SharedObject.getLocal('yp');
			so.data[key]=value;
			so.flush();
		}

		public function initBroadcasts():void
		{
			parseBroadcasts();
			dispatchEvent(new Event('bros'));
		}

		private var insertBro:Object;

		private function parseBroadcasts():void
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
					records.push({name: '定制广播', type: 1});
				}
				else
				{
					if (needInsert() && records[0].url)
						insertBro=records[0];
					else if (Capabilities.isDebugger && records[0].url)
						insertBro=records[0];
					else
						insertBro=null;
				}
				bs=bs.concat(records);
			}
			if (local || enabledInsert())
			{
				bs.push({name: '定制插播', type: 2});
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
		}

		private function needInsert():Boolean
		{
			return isLQ() || isJKL();
		}

		private function isLQ():Boolean
		{
			if (Capabilities.isDebugger)
				return true;
			var so:SharedObject=SharedObject.getLocal('yp');
			var un:String=so.data.username;
			return un.indexOf('利群') != -1;
		}

		private function isJKL():Boolean
		{
			if (Capabilities.isDebugger)
				return true;
			var so:SharedObject=SharedObject.getLocal('yp');
			var un:String=so.data.username;
			return un.indexOf('京客隆') != -1;
		}

		[Bindable]
		public var playingIndex:int;

		public var username:String;

		public function login(username:String, password:String, callback:Function):void
		{
			username=username.replace(' ', '');
			username=username.replace('：', ':');
			this.username=username;
			var f:File;
			progress='连接云系统';
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
				if (!vo.status)
					appendLog('LoginError:' + username + '-' + password + '-' + vo.errorResult);
				callback(vo);
			}, {username: username, password: password, serial_number: serial_number});
		}

		private function test():void
		{
//			var vo:InsertVO=new InsertVO();
//			vo._id='5399c4dd03aba48d3896c498';
//			recordDM(vo);
		}

		private function checkLog():void
		{
			if (!ServiceBase.id || !QNService.token || local || Capabilities.isDebugger)
				return;
			trace('CheckLog');
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
						if (re && re.status && f.exists)
							f.deleteFile();
					}, {key: upName});
				}
			}
		}

		[Bindable]
		public var updatable:Boolean;
		public var newVersion:String;
		public var versionLabel:String;
		public var updater:NativeApplicationUpdater;
		public var playingSong:SongVO;
		private var pv:PrepareWindow;
		public var version:String;
		[Bindable]
		public var progress:String='系统初始化';

//		public function isNewVersion(newVersion:String):Boolean
//		{
//			var arr:Array=version.split('.');
//			var v1:int;
//			var v2:int;
//			for each (var s:String in arr)
//			{
//				v1+=parseInt(s);
//			}
//			arr = newVersion.split('.');
//			for each (var s:String in arr)
//			{
//				v2+=parseInt(s);
//			}
//			return v2 > v1;
//		}

		private function getSB(uri:String, method:String='POST'):ServiceBase
		{
			var s:ServiceBase=serviceDic[uri + method];
			if (s)
				return s;
			s=new ServiceBase(uri, method);
			serviceDic[uri + method]=s;
			return s;
		}

		public function checkUpdate():void
		{
			if (local)
				return;
			LoadManager.instance.loadText(config.update + '?' + Math.random(), function(s:String):void
			{
				var o:Object=JSON.parse(s);
				if (o.version != version)
				{
					trace('New Version:' + o.version);
					newVersion=o.version;
					if (autoUpadte && !Capabilities.isDebugger)
					{
						recordLog(new LogVO(LogVO.AUTO_UPDATE_BEGIN, o.version, '从' + version + '自动更新版本到' + o.version));
						downloadUpdate();
					}
					else
					{
						updatable=true;
					}
				}
			});
		}
	}
}

