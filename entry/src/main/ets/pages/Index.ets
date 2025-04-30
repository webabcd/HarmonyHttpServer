/**
 * 用于演示如何使用 @webabcd/harmony-httpserver
 */

import { router } from '@kit.ArkUI'

@Entry
@Component
struct Index {

  build() {
    Column({space:10}) {
      Button("本地 http server 收到请求后，同步指定响应数据").onClick(() => { router.pushUrl({ url: 'pages/SyncDemo' }) })
      Button("本地 http server 收到请求后，异步指定响应数据").onClick(() => { router.pushUrl({ url: 'pages/AsyncDemo' }) })
    }
    .alignItems(HorizontalAlign.Start)
  }
}