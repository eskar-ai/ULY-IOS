@Entry
@Component
struct Index {
  build() {
    Column() {
      Text($r('app.string.host_title'))
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.host_ink'))
        .width('100%')

      Text($r('app.string.host_subtitle'))
        .fontSize(16)
        .fontColor($r('app.color.host_muted'))
        .margin({ top: 8 })
        .width('100%')

      Text($r('app.string.host_enable'))
        .fontSize(15)
        .fontColor($r('app.color.host_muted'))
        .margin({ top: 28 })
        .width('100%')

      TextInput({ placeholder: 'Type uygh or bugun…' })
        .margin({ top: 20 })
        .height(96)
        .backgroundColor(Color.White)
        .borderRadius(10)

      Text($r('app.string.host_privacy'))
        .fontSize(13)
        .fontColor($r('app.color.host_muted'))
        .margin({ top: 24 })
        .width('100%')
    }
    .padding(24)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.host_bg'))
    .alignItems(HorizontalAlign.Start)
  }
}
