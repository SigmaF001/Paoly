# ผลการแก้บัค Paoly — 2 ตุลาคม 2026

## สิ่งที่แก้

- เก็บบัญชี รายการ และหมวดหมู่ใน snapshot มี schema version ผ่าน shared_preferences ของโครงการ โหลดก่อนแสดงหน้าแรก และ serialize ลำดับ write
- เพิ่ม error banner พร้อม Retry; การกดบันทึกรายการรอผล persistence และ retry ด้วย ID เดิม รวมการแก้ค่าบนฟอร์มหลัง failure
- ข้อมูลการเงินที่อ่านไม่ได้ไม่ถูก reset/เขียนทับอัตโนมัติ
- แก้ยอดสลิปไม่มี comma, ปีไทยสองหลัก, วันไม่มีจริง และ regex ชื่อเดือนไทย ป้องกันนำวันที่นอกช่วงเข้า picker
- เพิ่ม iOS camera/photo usage descriptions; จัดการ picker errors และ mounted checks; ปิดปุ่ม OCR บน platform ที่ไม่รองรับ
- คำนวณเหรียญจากรายรับสะสมเป็นสตางค์ แก้การแบ่งรายการเพื่อได้รางวัลเพิ่ม การลบ/Undo ปรับรางวัลตามบัญชีรายการ และ startup reconcile รางวัลจากข้อมูลการเงินที่บันทึกแล้ว
- เหรียญที่ใช้ไปก่อนลบรายรับเป็นยอดชดเชยภายใน ไม่แสดงเหรียญติดลบ แต่หักจากรางวัลที่จะได้รับต่อไป เหรียญเดิมก่อนมีระบบ persistence คงอยู่เพราะไม่มีประวัติเงินเดิมให้ตรวจสอบ
- รายงานใช้ category ID แล้ว resolve ชื่อและ icon ปัจจุบันตามภาษา รองรับ fallback เมื่อหมวดถูกลบ
- ทั้งหน้าหลักและหน้ารายการมี confirmation และ Undo แบบเดียวกัน ปฏิทินใช้ localization ของ Flutter ตามภาษาของแอพ
- แก้การแสดง comma ของยอดติดลบและ smoke test ที่คาดหวังข้อมูลโดยไม่มี fixture
- ปรับ README ให้ตรงกับขอบเขต OCR จริง และเพิ่ม DESIGN.md/UX-CONTRACT.md เพื่อบันทึกเจ้าของ UI และกติกาที่ใช้ร่วมกัน

## หลักฐาน

- `flutter analyze --no-pub`: ผ่าน ไม่มี issues หลังแก้ lint

- `flutter test --no-pub`: ผ่าน 21 tests — persistence/reload, rapid writes, malformed snapshot, failure/retry, interrupted rewards, delete/Undo, spent rewards, parser, formatter, widget smoke, deletion interaction และหมวดหมู่รายงานภาษาอังกฤษ
- `flutter build web --no-pub`: ผ่าน สร้าง `build/web` และ Wasm dry run ผ่าน
- `plutil -lint ios/Runner/Info.plist`: ผ่าน
- `git diff --check`: ผ่าน
- `npx --yes -p @google/design.md designmd lint DESIGN.md`: 0 errors, 0 warnings
- frontend-design-premium strict static audit: 0 findings (`/tmp/paoly-fixed-ui-audit.json`)

## ข้อจำกัด

- ยังไม่ได้ทดสอบ kill/relaunch บนอุปกรณ์จริง, native Android/iOS build หรือเปิดกล้องจริง
- Parser tests ใช้ข้อความจาก native-channel mocks ไม่ใช่การวัด OCR จากภาพจริง โมเดล Latin ไม่รองรับอ่านข้อความไทยเต็มรูปแบบ
- shared_preferences เป็น storage ในเครื่องตามสถาปัตยกรรมเดิม ไม่ใช่ระบบสำรองหรือฐานข้อมูลที่รับประกัน durability ทุกกรณี การถอนแอพ/ล้างข้อมูลทำให้ข้อมูลหายได้
- ฟีเจอร์สำรองข้อมูล โอนระหว่างบัญชี งบประมาณ และรายการประจำยังเป็นข้อเสนอจากรายงาน ไม่ได้รวมในคำสั่งแก้บัคนี้
- Static UI audit และ widget tests ไม่ได้ครอบคลุม accessibility และ responsive ทุกขนาด
