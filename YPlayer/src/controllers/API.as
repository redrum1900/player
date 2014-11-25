package controllers
{
	import com.greensock.TweenLite;
	import com.pamakids.components.PAlert;
	import com.pamakids.events.ODataEvent;
	import com.pamakids.manager.FileManager;
	import com.pamakids.manager.LoadManager;
	import com.pamakids.manager.PopupManager;
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
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;

	import mx.core.UIComponent;
	import mx.formatters.DateFormatter;
	import mx.utils.UIDUtil;

	import spark.components.Alert;
	import spark.components.SkinnableContainer;

	import models.InsertVO;
	import models.LogVO;
	import models.MenuVO;
	import models.SongVO;
	import models.TimeVO;

	import org.osmf.events.TimeEvent;

	import views.BroadcastPanel;
	import views.ControllerLoginView;
	import views.LoginView;
	import views.Main;
	import views.MessageWindow;
	import views.SelectCacheView;
	import views.windows.PrepareWindow;

	public class API extends Singleton
	{
		[Bindable]
		public var local:Boolean=false; //是否本地
		public var online:Boolean=true; //是否在线
		public var isTest:Boolean=false; //是否是测试版
		public var isTool:Boolean=false; //是否作为下载mp3工具使用
		public var menuChange:Boolean; //歌单是否变化
		public var onLogin:Boolean=false;
		[Bindable]
		public var showTrace:Boolean=false; //是否显示Log.Trace信息面板

		public var enableFunctions:Array=['record'];
//		public var enableFunctions:Array=['record', 'insert'];

		private var serviceDic:Dictionary;
		private var refreshTimer:Timer;

		public var contactInfo:String='客服电话1：010-51244395\n客服电话2：010-51244052\nQQ1：王萍 99651674\nQQ2：杨丹丹 1690762409\nQQ3：段颖 3779317';
		private var nowOffset:Number=0;
		public var config:Object; //本地获取的json文件信息
		private var autoUpadte:Boolean; //是否自动更新
		public var serial_number:String;
		private var day:Number;

		public var logPath:String='';
		public var logFile:String='';
		public var conStatus:Boolean=false; //当前是否在播放广播

		private var noCacheDirInConfig:Boolean;

		public function API()
		{
			var o:Object=getConfig();
			isTest=o.test; //从配置文件获取是否测试版
			local=o.local; //从配置文件获取是否本地版
			autoUpadte=o.auto_update; //从配置文件获取是否自动更新
			broadcasts=o.broadcasts;
			showTrace=o.trace;
//			showTrace=true;
			config=o;
			if (!config.cacheDir)
				noCacheDirInConfig=true;

			if (config.insert_list)
				enableFunctions.push('insert');

			if (!config.sn)
				config.sn=UIDUtil.createUID();
			serial_number=config.sn;
			version=config.version;
			if (config.id)
				ServiceBase.id=config.id;
			serviceDic=new Dictionary();
			QNService.HOST='http://yfcdn.qiniudn.com/';
			setLogPath();

			var b:Boolean=o.debug == null ? Capabilities.isDebugger : o.debug;
			if (b)
			{
				var file:File=File.applicationStorageDirectory.resolvePath('log');
				if (file.exists)
					Log.Trace('log:' + FileManager.readFile(file.nativePath, false, true));

				ServiceBase.HOST='http://localhost:18080/api';
			}
			else
				ServiceBase.HOST=isTest ? 'http://t.yuefu.com/api' : 'http://m.yuefu.com/api';

//			if (config.username && config.password)
//			{
//				saveConfig();
//			}

			if (local)
			{
				online=false;
				FileManager.savedDir=File.applicationDirectory.resolvePath('local').nativePath + '/';
				setDefaultLoaclDMS();
			}
			else
			{
				getUploadToken();
				getNowTime();
			}
			setYPData('startup', new Date().getTime());
			setYPData('refreshTime', new Date().getTime());
			refreshTimer=new Timer(1000); //定时从服务器发送请求获取最新歌单
			refreshTimer.addEventListener(TimerEvent.TIMER, refreshHandler);
		}

		/**
		 * 从config.json获取信息
		 * @return
		 *
		 */
		public function getConfig():Object
		{
			var o:Object=FileManager.readFile('config.json');
			if (!o)
				o=FileManager.readFile('config.json', true, true);
			//			Log.Trace(o);
			if (o is String)
				o=JSON.parse(o + '');
			return o;
		}


		/**
		 * 设置默认本地定制插播
		 *
		 */
		public function setDefaultLoaclDMS():void
		{
			var arr:Array=FileManager.readFile('insertMenus.yp') as Array;
			if (local || enabledInsert())
			{
				if (!arr || arr.length == 0)
				{
					arr=[setLocalDMS()];
					FileManager.saveFile('insertMenus.yp', arr);
				}
			}
		}

		/**
		 * 设置默认插播
		 *
		 */
		public function setLocalDMS():MenuVO
		{
			var dmm:MenuVO=new MenuVO();
			dmm.type=MenuVO.DM;
			dmm.begin_date=new Date(now.fullYear, now.getMonth(), now.getDate(), 0, 0, 0, 0);
			dmm.end_date=new Date(now.fullYear, now.getMonth(), now.getDate(), 0, 0, 0, 0);
			dmm.name='默认列表';
			return dmm;
		}

		/**
		 *设置日志路径
		 * @return
		 *
		 */
		public function setLogPath():void
		{
			logPath='log/play' + DateUtil.getYMD(now, 0, '_') + '.log';
			Log.logPath=File.applicationStorageDirectory.resolvePath(logPath).nativePath;
			logFile=File.applicationStorageDirectory.resolvePath('log').nativePath;
		}

		public function getRecordLimit():int
		{
			return config.insert_conf.record_limit;
		}

		private function enabledInsert():Boolean
		{
			return enableFunctions.indexOf('insert') != -1;
		}

		/**
		 * 获取本地定制插播
		 * @return
		 *
		 */
		public function getLocalDMS():Array
		{
			var arr:Array=FileManager.readFile('insertMenus.yp') as Array;
			return objectToVO(arr, MenuVO);
		}

		/**
		 * 数组转换，object转换VO
		 * @param arr 从yp文件读取的数组
		 * @param toClass 需要转换成的VO
		 * @return
		 *
		 */
		public function objectToVO(arr:Array, toClass:*):Array
		{
			var rearr:Array=new Array();
			for each (var o:Object in arr)
			{
				rearr.push(CloneUtil.convertObject(o, toClass));
			}
			return rearr;
		}

		public function updateLocalDMS(arr:Array):void
		{
			FileManager.saveFile('insertMenus.yp', arr);
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

		/**
		 * 下载更新的软件
		 * @param callback
		 *
		 */
		public function downloadUpdate(callback:Function=null):void
		{
			LoadManager.instance.load('http://yfcdn.qiniudn.com/file/' + newVersion + '/' + config.swf, function(b:ByteArray):void
			{
				checkingUpdate=false;
				if (updateFileSize != b.length)
				{
					recordLog(new LogVO(LogVO.WARNING, newVersion, '版本更新文件大小有问题'));
					TweenLite.delayedCall(3, downloadUpdate);
					return;
				}
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
						config.version=newVersion;
						saveConfig();
						if (version != newVersion) //如果当前版本号跟新获取到版本好不同，则提示更新成功
						{
							recordLog(new LogVO(LogVO.AUTO_UPDATE_END, newVersion, '版本自动更新成功'));
							if (updateLog)
								PAlert.show(updateLog, '软件升级成功');
							if (!playingSong) //如果当前没有歌曲播放，则重新启动软件
								reboot();
							else
								needReboot=true;
						}
						version=newVersion;
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
				checkingUpdate=false;
				if (autoUpadte)
				{
					recordLog(new LogVO(LogVO.WARNING, newVersion, '版本自动更新失败'));
					return;
				}
				if (callback != null)
					callback(0)
			});
		}

		private function get formatedNow():String
		{
			var df:DateFormatter=new DateFormatter('YY-MM-DD HH:MM:SS');
			return df.format(now);
		}

		/**
		 * 重新启动
		 * @param forUpdate
		 *
		 */
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
				n.runCmd(args, ShowCmdWindow.HIDE, 1000); //延迟执行命令行
				NativeApplication.nativeApplication.exit(); //关闭程序
			});
		}

		private var gotServerTime:Boolean;

		/**
		 * 从服务器获取时间
		 */
		private function getNowTime():void
		{
			var u:URLRequest=new URLRequest('http://m.yuefu.com/now');
			var ul:URLLoader=new URLLoader();
			ul.addEventListener(Event.COMPLETE, function(e:Event):void
			{
				if (ul.data)
				{
					gotServerTime=true;
					var date:Date=NodeUtil.getLocalDate(ul.data);
					nowOffset=date.getTime() - now.getTime();
					setYPData('startup', now.getTime());
					setYPData('refreshTime', now.getTime());
					day=now.day;
				}
				Log.Trace('Now Offset:' + nowOffset);
			});
			ul.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void
			{
				appendLog('GetNow Error' + e.toString());
				TweenLite.killDelayedCallsTo(getNowTime);
				TweenLite.delayedCall(600, getNowTime);
			});
			ul.addEventListener(HTTPStatusEvent.HTTP_STATUS, function(e:HTTPStatusEvent):void
			{
				if (e.status && e.status != 200)
				{
					TweenLite.killDelayedCallsTo(getNowTime);
					TweenLite.delayedCall(600, getNowTime);
					appendLog('GetNow Error' + e.toString());
				}
			});
			ul.load(u);
		}


		/**
		 * 获取服务器上传令牌，用来上传本地错误日志
		 */
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
				TweenLite.delayedCall(600, getUploadToken);
			});
			ul.addEventListener(HTTPStatusEvent.HTTP_STATUS, function(e:HTTPStatusEvent):void
			{
				if (e.status && e.status != 200)
				{
					TweenLite.killDelayedCallsTo(getUploadToken);
					TweenLite.delayedCall(600, getUploadToken);
					appendLog('GetUploadToken Error' + e.toString());
				}
			});
			ul.load(u);
		}

		public function get now():Date
		{
			return isTest ? new Date() : new Date(new Date().getTime() + nowOffset);
		}

		/**
		 * Timer监听事件，从服务器发送请求获取最新歌单
		 * @param event
		 *
		 */
		protected function refreshHandler(event:TimerEvent):void
		{
			if (local) //如果是本地版，则不获取新歌单
				return;
			if (refreshTimer.currentCount % 60 == 0) //每个60秒触发一次
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
				if (!gotServerTime)
					getNowTime();
			}
		}


		/**
		 *检查登录状况
		 *
		 */
		private function checkLogin():void
		{
			if (local)
				return;
			if (!ServiceBase.id)
			{
//				var so:SharedObject=SharedObject.getLocal('yp');
				getSB('user/login').call(function(vo:ResultVO):void
				{
					if (vo.status)
						ServiceBase.id=vo.results.id + '';
					else
						appendLog('LoginError:' + config.username + '-' + config.password + '-' + vo.errorResult);
				}, {username: config.username, password: config.password});
			}
		}

		public var main:Main;

		/**
		 *更新数据文件
		 *
		 */
		private function refreshData():void
		{
			var pn:String;
			if (!playingInfo)
			{
				if (playingSong && menu) //如果当前正在播放歌曲，则显示播放歌曲和来自歌单，否则显示当前时间
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
				Log.Trace('Refreshed');
				var brosChanged:Boolean;
				var daychanged:Boolean; //是否过了一天
				if (day != now.day && !initializing && !playingSong)
				{
					daychanged=true;
					day=now.day;
					setLogPath();
				}
				if (vo.status && !pv)
				{
					var menus:Array=getMenus();
					var brosChanged:Boolean;
					if (compareBros(vo.results.bros))
					{
						brosChanged=true;
						if (vo.results.bros)
							FileManager.saveFile('bros.yp', vo.results.bros) //保存新的广播单
						initBroadcasts();
					}
					var menuChanged:Boolean=compareMenus(menus, vo.results.menus as Array);
					if (menuChanged || daychanged)
					{ //如果歌单发生变化或者过了一天
						var playingValid:Boolean=checkPlayingValid();
						if (daychanged || !playingValid)
						{
							menu=null;
							songs=null;
						}
						update_time=vo.results.update_time;
						if (readyToUpdate)
						{
							var o:Object=checkUncachedMenu();
							if (!o && menuChanged)
								initMenu();
						}
					}
					else if (brosChanged)
					{ //如果广播歌单发生了变化
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
					if (vo.results.log)
						uploadUseLog();
					Log.info('DayChanged:' + daychanged + ' BrosChanged:' + brosChanged + ' MenuChanged:' + menuChanged);
				}
				else if (!vo.status)
				{
					appendLog('RefreshFailed：' + vo.errorResult);
				}
				if (daychanged)
					initMenu();
				Log.info('daychanged:' + daychanged, ' brosChanged:' + brosChanged, 'menuChanged:' + menuChange);
			}, {startup: getYPData('startup'), version: version, playing: pn, serial_number: serial_number});

		}

//		private var rebootByCommand:Boolean;


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
			var logs:Array=config.logs;
			if (!logs)
				logs=[];
			if (o)
			{
				o.created_at=now.getTime();
				logs.push(o);
				config.logs=logs;
				saveConfig();
			}
			getSB('log/record').call(function(vo:ResultVO):void
			{
				if (vo.status)
				{
					config.logs=null;
					saveConfig();
				}
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
			var arr:Array=config.plaied;
			if (!arr)
			{
				arr=[];
				config.plaied=arr;
			}
			arr.push({id: ivo._id, plaied: now.toUTCString()});
			saveConfig();
			getSB('dm/record').call(function(vo:ResultVO):void
			{
				if (vo.status)
					config.plaied=null;
				else
					appendLog('RecordDM Error:' + vo.errorResult);
			}, {dms: JSON.stringify(arr), version: version, serial_number: serial_number});
		}

		public function appendLog(log:String):void
		{
			Log.warn(log);
			var path:String='log/' + DateUtil.getYMD(now, 0, '_') + '.log';
			var file:File;
			if (path.charAt(0) == '/')
				path=logPath.substr(1);
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
				Log.Trace('save file error', error);
			}

		}

		private function createDirectory(path:String):void
		{
			var arr:Array=path.match(new RegExp('.*(?=/)'));
			if (!arr || !arr.length)
				return;
			var directory:String=arr[0];
			var file:Object=File.applicationStorageDirectory.resolvePath(directory);
			if (!file.exists)
			{
				Log.Trace("FileCache - Directory not found, create it !");
				file.createDirectory();
			}
		}

		/**
		 * 对比当前广播单与新获取的广播单
		 * @param arr 服务器获取的广播单
		 * @return Boolean
		 *
		 */
		private function compareBros(arr:Array):Boolean
		{
			var changed:Boolean;
			var bs:Array=FileManager.readFile('bros.yp') as Array;
			if (bs)
			{
				if (bs.length != arr.length) //如果两个歌单长度不同，则返回true
				{
					changed=true;
				}
				else
				{
					for each (var o1:Object in bs) //如果歌单长度相同，则遍历对比
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
				changed=true; //如果本地没有歌单，则返回true
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

		/**
		 * 对比当前歌单与新获取的歌单，返回boolean
		 * @param menus 旧歌单
		 * @param newMenus 新歌单
		 * @return
		 *
		 */
		private function compareMenus(menus:Array, newMenus:Array):Boolean
		{
			var changed:Boolean=false;
			if (!newMenus)
				return false;
			if (!menus || menus.length != newMenus.length)
			{ //如果旧歌单不存在或者新歌单与旧歌单长度不相同，则直接保存新歌单
				FileManager.saveFile('menus.yp', newMenus);
				changed=true;
				Log.info('menu changed');
			}
			else
			{ //如果新旧歌单长度相同，则遍历歌单进行对比，如果发现不同，则保存新歌单
				for (var i:int=0; i < menus.length; i++)
				{
					var m1:Object=menus[i];
					var m2:Object=newMenus[i];
					if (m1._id != m2._id || m1.updated_at != m2.updated_at)
					{
						changed=true;
						Log.info('menu changed');
						FileManager.saveFile('menus.yp', newMenus);
						break;
					}
				}
			}
			return changed;
		}

		/**
		 * 读取本地歌单
		 * @return
		 *
		 */
		private function getMenus():Array
		{
			var arr:Array=FileManager.readFile('menus.yp') as Array;
			return arr;

		}

		/**
		 * 从网络获取歌单
		 */
		public function getMenuList():void
		{
			Log.Trace('saved_dir', FileManager.savedDir);
			progress='连接云系统成功，开始获取新内容';
			if (menu || !FileManager.savedDir)
				return;
			try
			{
				var menus:Array=getMenus();

				if (online && !local)
				{
					getSB('menu/list/2', 'GET').call(function(vo:ResultVO):void
					{
						if (vo.status)
						{
							if (vo.results.length)
							{
								compareMenus(menus, vo.results as Array); //对比新旧歌单
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
						Log.info('getMenuList --menuChange:' + menuChange);
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

		/**
		 * 获取当前时段的歌曲
		 */
		public function getCurrentTimeSongs():Array
		{
			var vo:SongVO;
			var arr:Array=[];
			for each (var t:TimeVO in menu.list)
			{
				sameDate(t.begin);
				sameDate(t.end);
				var bt:Number=t.begin.getTime();
				var nt:Number=now.getTime();
				var et:Number=t.end.getTime();
				//跨天后当前时间与始末时间处理
				if (bt > et)
				{
					if (now.hours > 12)
						et+=24 * 60 * 60 * 1000;
					else
						bt-=24 * 60 * 60 * 1000;
				}
				if (bt <= nt && et >= nt)
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

		/**
		 * 获取随机的歌曲
		 */
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
		public var broadcasts:Array; //广播歌单列表

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

		/**
		 * 判断歌单是否可用，即当前时间是否在该歌单播放时段内
		 * @param menu
		 * @return
		 *
		 */
		private function menuDateValid(menu:Object):Boolean
		{
			if (!menu || !menu.begin_date || !menu.end_date)
				return false;
			var n:Date=now;
			n=new Date(n.getFullYear(), n.getMonth(), n.getDate(), 0, 0, 0, 0);
			return n.getTime() >= menu.begin_date.getTime() && n.getTime() <= menu.end_date.getTime();
		}

		private function menuValid(menu:Object):Boolean
		{
			if (!menu || !menu.begin_date || !menu.end_date)
				return false;
			return menuDateValid(menu) && dayValidate(menu.tags);
		}

		private function deleteInvalidMenu(id:String):void
		{
			var menus:Array=getMenus();
			;
			for (var i:int; i < menus.length; i++)
			{
				if (id == menus[i]._id)
					menus.splice(i, 1);
			}
			FileManager.saveFile('menus.yp', menus);
		}

		private function checkPlayingValid():Boolean
		{
			var b:Boolean=true;
			if (!gotServerTime)
				return b;
			var clearedSize:Number=0;
			var clearInfo:String='';
			var o:Object;
			var arr:Array=config.cachedmenus;
			var f:File;
			if (menu && !menuDateValid(menu))
			{
				deleteInvalidMenu(menu._id);
				arr.splice(arr.indexOf(menu._id), 1);
				clearInfo+='清空了歌单：' + menu.name + ' ';
				if (songs && songs.length)
				{
					for each (o in songs)
					{
						if (o.url && o.url.indexOf('http') != -1)
						{
							f=new File(FileManager.savedDir + URLUtil.getCachePath(o.url));
							Log.Trace(f.name, f.size);
							clearedSize+=f.size;
							f.deleteFileAsync()
						}
					}
				}
				b=false;
				menu=null;
				songs=null;
			}
			if (dmMenus && dmMenus.length)
			{
				for each (var dm:Object in dmMenus)
				{
					if (!menuDateValid(dm))
					{
						deleteInvalidMenu(dm._id);
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
				config.cachedmenus=arr;
				saveConfig();
				Log.Trace(clearedSize / 1024, clearInfo);
				recordLog(new LogVO(LogVO.CLEAR_CACHE, Math.round(clearedSize / 1024) + '', clearInfo + ' ' + DateUtil.getYMD(now)));
			}
			return b;
		}

		private var dmMenus:Array;

		private var initializing:Boolean;

		/**
		 * 获取没有缓存的歌单
		 * @return
		 *
		 */
		private function getUncachedMenu():Object
		{
			var menus:Array=getMenus();
			var menu:Object;
			var o:Object;
			var n:Date=now;
			n=new Date(n.getFullYear(), n.getMonth(), n.getDate())
			var i:int;
			for (i=0; i < menus.length; i++)
			{
				o=menus[i];
				if (o.end_date && o.begin_date)
				{
					if (!hasCached(o._id))
					{
						menu=o;
						break;
					}
				}
			}
			return menu;
		}


		/**
		 * 初始化歌单
		 *
		 */
		public function initMenu():void
		{
			if (initializing)
				return;
			initializing=true;
			var menus:Array=getMenus();
			if (menus && menus.length)
			{ //如果有本地歌单
				var i:int;
				var listMenu:Object;
				dmMenus=[];
				var o:Object;
				var n:Date=now;
				n=new Date(n.getFullYear(), n.getMonth(), n.getDate());
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
					LoadManager.instance.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
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
					LoadManager.instance.loadText(QNService.HOST + o._id + '.json', function(data:String):void //获取服务器最新歌单
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

		/**
		 * 请求歌单详细信息失败触发事件
		 * @param event
		 *
		 */
		protected function ioErrorHandler(event:Event):void
		{
			if (initializing)
			{
				initializing=false;
				if (getUncachedMenu().length)
				{
					PAlert.show('获取歌单详情失败，请稍候再试', '初始化失败', null, function():void
					{
						initMenu();
					}, PAlert.CONFIRM, '再试一次', '', true);
				}
				else
				{
					online=false;
					initMenu();
				}

			}
		}

		public var times:Array=[];
		public var currentTime:Object;

		/**
		 * 同步日期
		 */
		public function sameDate(date:Date):void
		{
			date.date=now.date;
			date.month=now.month;
			date.fullYear=now.fullYear;
		}

		/**
		 *  判断当前时间是否在设置循环播放
		 * @return
		 *
		 */
		public function get isCurrentTimeLoop():Boolean
		{
			var b:Boolean;
			if (!menu)
				return b;
			for each (var o:Object in menu.list)
			{
				sameDate(o.begin);
				sameDate(o.end);
				var bt:Number=o.begin.getTime();
				var nt:Number=now.getTime();
				var et:Number=o.end.getTime();
				if (bt > et)
				{
					if (now.hours > 12)
						et+=24 * 60 * 60 * 1000;
					else
						bt-=24 * 60 * 60 * 1000;
				}

				if (bt <= nt && et >= nt)
				{ //若在播放时段内，歌单是否选择歌曲循环
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
				Log.Trace(DateUtil.getYMD(vo.begin_date));
				Log.Trace(DateUtil.getYMD(vo.end_date));
				Log.Trace(DateUtil.getYMD(now));
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
						d1=DateUtil.getDateByHHMMSS(o.playTime, now);
					var v1:Number=d1.getTime();
					d1.seconds+=o.duration;
					var v2:Number=d1.getTime();
					for each (var o2:Object in locals)
					{
						var d:Date=DateUtil.getDateByHHMMSS(o2.playTime, now);
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

		/**
		 * 解析歌单
		 * @param songMenu背景音菜单
		 * @param dmMenu广播DM菜单
		 * @param onlyParse
		 * @return
		 */
		public function parseMenu(songMenu:Object, dmMenu:Object, onlyParse:Boolean=false):Object
		{
			LoadManager.instance.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			var o:Object=songMenu;
			if (o)
			{
				o.end_date=NodeUtil.getLocalDate(o.end_date);
				o.begin_date=NodeUtil.getLocalDate(o.begin_date);
			}
			else if (this.menu)
			{
				o=this.menu;
			}

			var songs:Array=[];
			parseBroadcasts();
			var ivo:InsertVO;
			var a:Array=[];
			var localInsertedMenu:MenuVO;
			if (local || (onLogin && enabledInsert()))
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
					ivo.playTime=DateUtil.getDateByHHMMSS(dm.playTime, now);
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
				var insert_conf:Object=config.insert_conf;
				var bd:Date=DateUtil.getDateByHHMMSS(insert_conf.begin, now);
				var ed:Date=DateUtil.getDateByHHMMSS(insert_conf.end, now);
				while (bd.getTime() < ed.getTime())
				{
					ivo=new InsertVO();
					ivo.type=InsertVO.AUTO_INSERT;
					ivo.name=insertBro.name;
					ivo.url=new File(FileManager.savedDir + insertBro.url).url;
					ivo.playTime=DateUtil.clone(bd);
					a.push(ivo);
					bd.minutes+=insert_conf.interval;
				}
			}

			if (dmMenu && dmMenu)
			{
				//单独缓存新的DM列表时，将之前的DM列表整合到一起
				if (this.dmMenu && this.dmMenu.dm_list && !hasCached(dmMenu._id))
				{
					for each (var ivo:InsertVO in this.dmMenu.dm_list)
					{
						dmMenu.dm_list.push(ivo);
					}
				}
//					dmMenu.dm_list.concat(this.dmMenu.dm_list)

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

			/*
			以下为对歌单歌曲解析，歌单的时段及详细曲目
			*/
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
					if (oo.begin is String)
					{
						oo.begin=DateUtil.getDateByHHMMSS(oo.begin, now);
						oo.end=DateUtil.getDateByHHMMSS(oo.end, now);
					}
					if (!playingSong && dateValidate(o.begin_date, o.end_date))
						times.push({begin: oo.begin, end: oo.end, loop: Boolean(oo.loop)});
					playTime=DateUtil.clone(oo.begin);
					var arr:Array=[];
					if (oo.songs)
					{
						var songNum:int=0;
						for (var j:int=0; j < oo.songs.length; j++)
						{
							var s:Object=oo.songs[j];
							var song:SongVO=new SongVO();
							if (s is SongVO)
								song=s as SongVO;
							else
							{
								song.allow_circle=s.allow_circle;
								s=s.song;
								song.playTime=DateUtil.clone(playTime);
								song.size=s.size;
								song._id=s._id;
								song.url=QNService.HOST + s.url + '?p/1/avthumb/mp3/ab/' + o.quality + 'k';
								song.name=s.name
								song.duration=s.duration;
							}
							arr.push(song);
							songs.push(song);
							if (playingSong && playingSong.playTime.getTime() == song.playTime.getTime())
								playingSong=song;
							if (dmMenu && dmMenu.dm_list && !oo.loop)
							{
								var t1:Number=playTime.getTime();
								playTime.seconds+=s.duration;
								var t2:Number=playTime.getTime();
								for each (var dmivo:InsertVO in dms)
								{
									var t3:Number=dmivo.playTime.getTime();
									if (t1 <= t3 && t3 <= t2)
									{
										if (songs.indexOf(dmivo) == -1)
											songs.push(dmivo);
									}
								}
							}
							else if (s.duration)
								playTime.seconds+=s.duration;
							else
								Log.Trace('P', DateUtil.getHMS(song.playTime), s.url, s.name);
						}

					}
					oo.songs=arr;
				}
				Log.Trace('DMS:' + dms.length);
				o.list=CloneUtil.convertArrayObjects(o.list, TimeVO);
			}
//			this.menu=o.list;
			if (!onlyParse)
			{
				if (!playingSong && o && dateValidate(o.begin_date, o.end_date))
				{
					if (!this.menu || this.menu._id == o._id)
					{
						if (!pv && this.menu)
							AA.say('UPDATE');
						this.menu=CloneUtil.convertObject(o, MenuVO);
						this.dmMenu=dmMenu;
						this.songs=songs;
					}
					initializing=false;
				}
				else if (dmMenu && dateValidate(dmMenu.begin_date, dmMenu.end_date))
				{
					this.dmMenu=dmMenu;
					this.songs=songs;
					dmChanged=true;
					if (playingSong)
						playingIndex=songs.indexOf(playingSong);
					this.menu.list=o.list;
					AA.say('UPDATE');
					initializing=false;
				}
				if (updateForRecord)
				{
					this.songs=songs;
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
					if (readyToUpdate || !getUncachedMenu())
					{
						toPrepare(o, dmMenu, songs);
					}
					else if (getUncachedMenu() && !playingSong)
					{
						dispatchEvent(new Event('PLAY'));
						PAlert.show('只能在闲时 ' + update_time + '点之间进行更新，请到时再打开软件尝试');
					}
				}
			}
			return {songs: songs, dmMenu: dmMenu};
		}

		/**
		 * 对比歌单和歌曲，弹出更新媒资界面
		 * @param menu 歌单
		 * @param dmMenu 广播单
		 * @param songs 曲目列表
		 *
		 */
		private function toPrepare(menu:Object, dmMenu:Object, songs:Array):void
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

			if (!playingSong)
				progress='开始初始化内容';

			pv=new PrepareWindow(); //更新媒资界面
			var label:String="";
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
			if (menu)
				Log.info('ToPrepareMenu:' + menu.name);
			pv.addEventListener('loaded', function(e:ODataEvent):void
			{
				if (menu)
					Log.info('LoadedMenu:' + menu.name);
				initializing=false;
				progress='';
				if (e.data)
				{
					config.updatalog=e.data;
					saveConfig();
					uploadUpdateLog();
				}
//				else
//				{
//					checkMenuToUpdate();
//				}
				if (!playingSong || dmChanged)
				{
					initBroadcasts();
					dmChanged=false;
					dispatchEvent(new Event('PLAY'));
				}
				checkUncachedMenu();
				AA.say('CACHED');
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

		/**
		 *检查没有缓存的歌单
		 *
		 */
		private function checkUncachedMenu():Object
		{
			var menu:Object=getUncachedMenu();
			if (menu)
			{
				Log.info('toPrepareUncachedMenu:' + menu.name);
				LoadManager.instance.loadText(QNService.HOST + menu._id + '.json', function(data:String):void
				{
					var o:Object=JSON.parse(data);
					o.end_date=NodeUtil.getLocalDate(o.end_date);
					o.begin_date=NodeUtil.getLocalDate(o.begin_date);
					var n:Date=now;
					n=new Date(n.getFullYear(), n.getMonth(), n.getDate(), 0, 0, 0, 0);
					if (o.end_date.getTime() > n.getTime())
					{
						if (o.type == 1)
							parseMenu(o, null);
						else if (o.type == 2)
							parseMenu(null, o);
					}
				}, menu._id + '.json', function():void
				{
					PAlert.show('获取新歌单详情失败，请确保网络连接再试', '初始化失败', null, function():void
					{
						checkUncachedMenu();
					}, PAlert.CONFIRM, '再试一次', '', true);
				});
			}
			return menu;
		}


		public function hasCached(id:String):Boolean
		{
			var b:Boolean;
			var arr:Array=config.cachedmenus;
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
			if (local)
				return;
			var log:Object=config.updatalog;
			if (log)
			{
				log.version=version;
				log.serial_number=serial_number;
				if (!config.cachedmenus)
					config.cachedmenus=[];
				var menus:Array=config.cachedmenus;
				if (log.songMenu && menus.indexOf(log.songMenu) == -1)
					menus.push(log.songMenu);
				if (log.dmMenu && menus.indexOf(log.dmMenu) == -1)
					menus.push(log.dmMenu);
				saveConfig();
				getSB('/update/log').call(function(vo:ResultVO):void
				{
					if (vo.status)
					{
						config.updatalog=null;
//						checkMenuToUpdate();
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

//		private function checkMenuToUpdate():void
//		{
//			var menus:Array=FileManager.readFile('menus.yp') as Array;
//			var cached:Array=cachedSO.data.menus;
//			for each (var m:Object in menus)
//			{
//				if (cached.indexOf(m._id) == -1)
//				{
//					if (m.type == 1)
//					{
//						parseMenu(m, null);
//					}
//					else
//					{
//						parseMenu(null, m);
//					}
//					break;
//				}
//			}
//		}

//		public var dms:Array;

		/**
		 * 弹出来一个提示没有播放列表
		 *
		 */
		private function noPlayList():void
		{
			initializing=false;
			PAlert.show('您的播放歌单尚未准备完毕，请联系客服进行添加并保持网络连接', '初始化失败', null, function():void
			{
				online=true;
				getMenuList();
			}, PAlert.CONFIRM, '再试一次', '', true);
		}

		private function getYPData(key:String):Object
		{
			return config[key];
		}

		private function setYPData(key:String, value:Object):void
		{
			config[key]=value;
			saveConfig();
		}


		/**
		 *初始化广播列表
		 *
		 */
		public function initBroadcasts():void
		{
			parseBroadcasts();
			dispatchEvent(new Event('bros')); //广播事件，触发ListPanel.mxml中监听事件
		}

		private var insertBro:Object;

		/**
		 * 解析广播列表
		 * 待细看
		 */
		private function parseBroadcasts():void
		{
			var bs:Array=FileManager.readFile('bros.yp') as Array;
			if (bs)
			{
				for each (var o:Object in bs)
				{
					o.playTime=DateUtil.getDateByHHMMSS(o.playTime, now);
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
				var records:Array=config.records;
				if (!records)
				{
					records=[]
					records.push({name: '定制广播', type: 1});
				}
				else
				{
					var f:File;
					if (needInsert() && records[0].url)
					{
						f=new File(FileManager.savedDir + records[0].url);
						if (f.exists)
							insertBro=records[0];
					}
					else if (Capabilities.isDebugger && records[0].url)
					{
						f=new File(FileManager.savedDir + records[0].url);
						if (f.exists)
							insertBro=records[0];
					}
					else
						insertBro=null;
				}
				bs=bs.concat(records);
			}
			if (enabledInsert())
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
			return config.insert;
		}

		[Bindable]
		public var playingIndex:int;

		public var username:String;

		/**
		 * 存储账号信息到本地
		 */
		public function saveUserInfo(name:String, pwd:String, cacheDir:String, id:String):void
		{
			try
			{
				config.cacheDir=cacheDir;
				config.id=id;
				config.username=name;
				config.password=pwd;
				saveConfig();
			}
			catch (error:Error)
			{
				appendLog('SaveUserInfoError:' + error);
			}
		}


		/**
		 *存储设置信息到本地文件中
		 *
		 */
		public function saveConfig():void
		{
			try
			{
				var f:File=new File(File.applicationDirectory.resolvePath('config.json').nativePath);
				var fs:FileStream=new FileStream();
				fs.open(f, FileMode.WRITE);
				fs.writeMultiByte(JSON.stringify(config), 'utf-8');
				fs.close();
			}
			catch (error:Error)
			{
				appendLog('SaveConfigError:' + error);
			}
		}

		/**
		 * 获取账号和登录密码
		 */
		public function getUserInfo():Object
		{
			var o:Object={};
			var config:Object;
//			config=getConfig();
			Log.info('getUserInfoing……………………');
			if (config && config.username)
			{
				Log.info('LoginInfo exist');
				o.username=config.username;
				o.password=config.password;
				o.cacheDir=config.cacheDir;
				o.id=config.id;
//				Log.info(config.username);
				Log.info('Login---true---username:' + config.username + '----password:' + config.password);
			}
			else
			{
				Log.info('Login---false');
			}
			return o;
		}

		private var update_time:String;

		/**
		 * 登录
		 */
		public function login(username:String, password:String, callback:Function=null):void
		{
			username=username.replace(' ', '');
			username=username.replace('：', ':');
			this.username=username;
			var f:File;
			progress='连接云系统';
			//发送账号登录请求
			getSB('user/login').call(function(vo:ResultVO):void
			{
				var info:Object=getUserInfo();
				var cd:String=info.cacheDir; //缓存地址
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
					update_time=vo.results.update_time;
					ServiceBase.id=vo.results.id + '';
					if (cd && exists)
					{
						saveUserInfo(username, password, cd, vo.results.id);
						FileManager.savedDir=cd;
						FileManager.saveFile('bros.yp', broadcasts);
						getMenuList();
					}
					Log.info('username:' + username, 'password:' + password);
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
					if (vo.status || noCacheDirInConfig)
					{
						var sv:SelectCacheView=new SelectCacheView(); //缓存位置选择界面
						PopupBoxManager.popup(sv, function():void
						{
							FileManager.savedDir=config.cacheDir;
							if (vo.results && vo.results.hasOwnProperty('id'))
								saveUserInfo(username, password, FileManager.savedDir, vo.results.id);
							else
							{
								saveConfig();
							}
							if (broadcasts)
								FileManager.saveFile('bros.yp', broadcasts);
							getMenuList();
						});
					}
				}

				setDefaultLoaclDMS();
				onLogin=true;

				if (!vo.status)
				{
					if (!noCacheDirInConfig)
					{
						online=false;
						getMenuList();
						appendLog('LoginError:' + username + '-' + password + '-' + vo.errorResult);
					}
					else
					{
						var l:LoginView=new LoginView();
						PopupBoxManager.popup(l);
					}
				}

				if (callback != null)
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
			Log.Trace('CheckLog');
			var file:File=File.applicationStorageDirectory.resolvePath('log');
			if (file.exists && file.isDirectory)
			{
				var files:Array=file.getDirectoryListing();
				if (files.length)
				{
					var f:File=files.shift() as File;
					if (f.creationDate.date != now.date)
					{
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
		}

		[Bindable]
		public var updatable:Boolean;
		public var newVersion:String;
		public var versionLabel:String;
		public var updater:NativeApplicationUpdater;
		public var playingSong:SongVO;
		private var pv:PrepareWindow; //更新媒资窗口
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

		private function get readyToUpdate():Boolean
		{
			var readyToUpdate:Boolean=true;
			var ut:String=update_time;
			if (ut)
			{
				try
				{
					var h:int=now.getHours();
					var arr:Array=ut.split(' ');
					var bt:int=parseInt(arr[0]);
					var et:int=parseInt(arr[1]);
					if (bt > et)
					{
						if (h > 12)
							et+=24;
						else
							bt-=24
					}
					if (h < bt || h > et)
						readyToUpdate=false;
				}
				catch (error:Error)
				{
					appendLog('UpdateTime Error:' + error);
				}
			}
			return readyToUpdate;
		}

		/**
		 * 获取服务基类
		 * @param uri
		 * @param method
		 * @return
		 *
		 */
		private function getSB(uri:String, method:String='POST'):ServiceBase
		{
			var s:ServiceBase=serviceDic[uri + method];
			if (s)
				return s;
			s=new ServiceBase(uri, method);
			serviceDic[uri + method]=s;
			return s;
		}

		private var checkingUpdate:Boolean;
		private var updateFileSize:Number;
		private var updateLog:String;

		/**
		 * 检查更新
		 *
		 */
		public function checkUpdate():void
		{
			if (local || checkingUpdate || config.trace)
				return;
			checkingUpdate=true;
			var url:String=config.update; //下载地址
			if (isTest)
				url=url.replace('update', 'test');
			else
				url=url.replace('update', 'update_swf');
			LoadManager.instance.loadText(url + '?' + Math.random(), function(s:String):void
			{
				var o:Object=JSON.parse(s);
				updateFileSize=o.size;
				updateLog=o.log;
				if (o.version != version) //判断服务器是否是新版本
				{
					Log.Trace('New Version:' + o.version);
					newVersion=o.version;
					recordLog(new LogVO(LogVO.AUTO_UPDATE_BEGIN, o.version, '从' + version + '自动更新版本到' + o.version));
					if (!Capabilities.isDebugger) //如果当前不是调试版本，则下载更新程序
						downloadUpdate();
				}
				else
				{
					checkingUpdate=false;
				}
			});
		}

		/**
		 *上传用户使用日志
		 *
		 */
		public function uploadUseLog():void
		{
			Log.Trace('uploadLog');
			var file:File=File.applicationStorageDirectory.resolvePath('log');
			if (file.exists && file.isDirectory)
			{
				var files:Array=file.getDirectoryListing();
				if (files.length)
				{
					var f:File=files.pop() as File;
					for (var i:int=0; i < files.length; i++) //判断当前日志是否是播放日志
					{
						if (f.nativePath.indexOf('play') == -1)
							f=files.shift() as File;
						else
							break;
					}
					var upName:String=ServiceBase.id + '-' + DateUtil.getHMS(now) + '-' + f.name;
					QNService.instance.upload(f, function(r:Object):void
					{
						Log.Trace('上传日志成功：' + f.name);
					}, {key: upName});
				}
			}
		}

		public function clearInfo():void
		{
			config.username='';
			config.password='';
			config.cacheDir='';
			config.cachedmenus=[];
			saveConfig();
		}

		private var app:SkinnableContainer;
		private var isController:Boolean;

		public function controllerInit(app:SkinnableContainer):void
		{
			PAlert.PARENT=app;
			PopupBoxManager.PARENT=app;
			this.app=app;
			config=getConfig();
//			controllerLogin('red:q2', '994070');
			if (config.username && config.password)
			{
				controllerLogin(config.username, config.password);
			}
			else
			{
				var l:ControllerLoginView=new ControllerLoginView();
				PopupBoxManager.popup(l);
			}
		}

		public function controllerLogin(username:String, password:String, callback:Function=null):void
		{
			config.username=username;
			config.password=password;
			saveConfig();
			getSB('user/controller/login').call(function(vo:ResultVO):void
			{
				Log.info(JSON.stringify(vo.results));
				if (vo.status)
				{
					ServiceBase.id=vo.results.id;
					isController=vo.results.controller;
					if (!isController)
					{
						PAlert.show('您没有控制权限，请联系我们为您开通:\n客服电话1：010-51244395\n客服电话2：010-51244052\n您的序列号为：' + serial_number.split('-')[0], '提示', null, function(value:String):void
						{
							controllerLogin(config.username, config.password);
						}, PAlert.CONFIRM, '再试一次', '', true);
					}
					else
					{
						var bp:BroadcastPanel=new BroadcastPanel();
						bp.bros=vo.results.broadcasts;
						app.addElement(bp);
					}
				}
				else
				{
					//提示登录失败，需要重试，点击重试按钮后，再次调用自动登录的方法
				}
			}, {username: username, password: password, controller_number: serial_number});
		}

		/**
		 * 发送广播命令
		 * @param command
		 * @param callback
		 *
		 */
		public function sendCommand(command:String, callback:Function):void
		{
			getSB('user/command').call(function(vo:ResultVO):void
			{
				callback(vo);
			}, {command: command, controller_number: serial_number});
		}

		/**
		 * 获取播放广播命令
		 * @param callback
		 *
		 */
		public function getCommand(callback:Function):void
		{
			getSB('user/command', 'GET').call(function(vo:ResultVO):void
			{
				if (vo && vo.results == 'showMenu')
					callback(vo.results as String);
				else if (vo && vo.results == 'stop')
					callback(vo.results as String);
				else if (vo && vo.results == 'playInfo')
					callback(vo.results as String);
				else if (vo && vo.results.length != 0 && vo.results != '网络连接失败，请稍后再试')
					callback(JSON.parse(vo.results as String));
			}, {controller_number: serial_number});
		}

		/**
		 * 发送广播状态
		 * @param b
		 * @param callback
		 *
		 */
		public function sendStatus(b:String, callback:Function=null):void
		{
			getSB('command/status').call(function(vo:ResultVO):void
			{
				if (vo && callback)
					callback();
			}, {status: b});
		}

		/**
		 * 获取广播状态
		 * @param callback
		 *
		 */
		public function getStatus(callback:Function=null):void
		{
			var s:String=''
			getSB('command/status', 'GET').call(function(vo:ResultVO):void
			{
				if (vo)
				{
					var str:String=vo.results as String;
					callback(str);
				}
			});
		}
	}
}

