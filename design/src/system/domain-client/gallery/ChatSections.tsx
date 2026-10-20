// Gallery: chat bubbles in every kind and the conversation list, from the chat fixtures (client side, plus a hotel-side draft).
import { useState } from 'react'
import { conversations, messages, type Message } from '../../../mock'
import { ChatBubble, ChatDateDivider, ConversationRow } from '../Chat'
import { Section, Spec, useL } from './kit'

const msg = (id: string): Message => {
  const m = messages.find(x => x.id === id)
  if (!m) throw new Error(id)
  return m
}

export function ChatSection() {
  const l = useL()
  const [playing, setPlaying] = useState(false)
  const own: Message = { ...msg('msg-006'), text: { en: 'Hello Nouf, we need help designing the kosha.', ar: 'أهلًا نوف، نحتاج مساعدة في تصميم الكوشة.' }, origin: 'ar' }
  const english: Message = { ...own, id: 'msg-en', origin: 'en', from: 'planner', text: { en: 'Happy to help. Send me any photos you like, in English or Arabic.', ar: 'يسعدني ذلك.' } }
  const system: Message = { ...own, id: 'msg-sys', kind: 'system', from: 'system', text: { en: 'Handled by Hind Al-Enezi', ar: 'يتابع معكم هند العنزي' }, origin: 'en' }
  const long: Message = { ...own, id: 'msg-long', from: 'venue', origin: 'ar', text: { en: '', ar: 'وعليكم السلام ورحمة الله، هلا فيكم. نعم الخميس 14 يناير متاح للحفل النسائي في قاعة الدانة، ويمكننا تثبيت التاريخ لكم لمدة 24 ساعة بعد الموافقة. أرسلوا لنا عدد الضيوف التقريبي وسنجهز لكم عرض السعر.' } }
  return (
    <Section
      id="chat"
      title={l('Chat', 'المحادثة')}
      note={l(
        'Text is shown as typed, in its own language and direction; labels are never dialect. Own messages sit at inline-end in ink, received on ink-50; the tail corner is 4. Voice shows a waveform and the duration; documents show the file name as an LTR isolate.',
        'يُعرض النص كما كُتب بلغته واتجاهه؛ ولا تكون العناوين بلهجة محلية. رسائلكم عند نهاية السطر بالحبر والمستلمة على رمادي فاتح؛ وزاوية الذيل 4. الصوت يعرض موجة ومدة، والمستندات تعرض اسم الملف بعزل من اليسار إلى اليمين.',
      )}
    >
      <Spec state={l('Text · own and received · an English message in an Arabic thread · long text', 'نص · مرسل ومستلم · رسالة إنجليزية في محادثة عربية · نص طويل')}>
        <ChatDateDivider date="2026-11-12" />
        <ChatBubble message={msg('msg-005')} />
        <ChatBubble message={own} />
        <ChatBubble message={english} />
        <ChatBubble message={long} />
        <ChatBubble message={system} />
      </Spec>
      <Spec state={l('Voice · idle and playing (progress shown)', 'صوت · متوقف ويعمل (مع التقدم)')}>
        <ChatBubble message={msg('msg-003')} side="hotel" />
        <ChatBubble message={msg('msg-019')} playing={playing} progress={playing ? 0.4 : 0} onPlay={() => setPlaying(v => !v)} />
      </Spec>
      <Spec state={l('Image · document · draft (hotel side, never visible to the couple)', 'صورة · مستند · مسودة (جهة المكان، لا تظهر للعروسين)')}>
        <ChatBubble message={msg('msg-018')} />
        <ChatBubble message={msg('msg-011')} />
        <ChatBubble message={msg('msg-004')} side="hotel" />
      </Spec>
      <Spec state={l('Structured cards · meeting, quote request', 'بطاقات منظمة · اجتماع وطلب عرض سعر')}>
        <ChatBubble message={msg('msg-007')} />
        <ChatBubble message={msg('msg-009')} side="client" />
      </Spec>
    </Section>
  )
}

export function ConversationSection() {
  const l = useL()
  const rows = ['conv-aurelia-reem', 'conv-planner-nouf', 'conv-vendor-lamha', 'conv-jawharat-reem', 'conv-support-reem', 'conv-lumi-reem']
  return (
    <Section
      id="conversation-row"
      title={l('Conversation row', 'صف المحادثة')}
      note={l(
        'Monogram, name, one line of preview, the time and the gold unread count. An unread preview is strong; a pinned thread without unread shows the pin.',
        'حرف أول واسم وسطر معاينة واحد والوقت وعدّاد ذهبي لغير المقروء. معاينة غير المقروء بخط أوضح؛ والمحادثة المثبتة بلا رسائل جديدة تعرض الدبوس.',
      )}
    >
      <Spec state={l('The Messages list (Reem’s six threads)', 'قائمة الرسائل (محادثات ريم الست)')}>
        <div className="gc-list">
          {rows.map(id => {
            const c = conversations.find(x => x.id === id)!
            const last = [...messages.filter(m => m.conversationId === id && !m.draft)].pop() ?? null
            return <ConversationRow key={id} conversation={c} last={last} onOpen={() => undefined} />
          })}
        </div>
      </Spec>
    </Section>
  )
}
