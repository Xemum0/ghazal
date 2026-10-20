// Gallery: the visit pieces (ADR 0033 D9): RoleBadge, ParticipantStrip, the group chat (ChatBubble with a sender line and a glyph on system lines)
// and VisitCard, driven by the visit fixtures and the three-way group thread of the story visit. Rendered at #/gallery/voucher.
import { groupThreadFor, visits, type Message, type ThreadMember } from '../../../mock'
import { useLang } from '../../../shell/lang'
import { ChatBubble, ChatDateDivider } from '../../domain-client'
import { Row, Section, Spec, useL } from '../../domain-client/gallery/kit'
import { ParticipantStrip } from '../../domain-visits/ParticipantStrip'
import { RoleBadge } from '../../domain-visits/RoleBadge'
import { VisitCard } from '../../domain-visits/VisitCard'

function useThread(visitId: string, side: 'client' | 'hotel') {
  const t = groupThreadFor(visitId, side)
  if (!t) throw new Error(`fixture ${visitId}`)
  return t
}

export function RoleBadgeSection() {
  const l = useL()
  const t = useThread('visit-aurelia-reem', 'client')
  return (
    <Section
      id="role-badge"
      title={l('Role badges and members', 'شارات الأدوار والأعضاء')}
      note={l(
        'Exactly three roles in every visit group chat: Client, Hotel representative, Ghazal support. A text chip, never a glyph that could pass for a face; monogram avatars only. The roles differ by tone and by words, never by colour alone.',
        'ثلاثة أدوار فقط في كل محادثة زيارة جماعية: العميل وممثل الفندق ودعم غزل. شارة نصية بلا رمز قد يُظن وجهًا، وصور رمزية بالحرف الأول فقط. تختلف الأدوار بالنبرة والكلمات لا باللون وحده.',
      )}
    >
      <Spec state={l('Badges · client · hotel representative · support · “You”', 'الشارات · العميل · ممثل الفندق · الدعم · «أنتم»')}>
        <Row>
          <RoleBadge role="client" />
          <RoleBadge role="hotel_representative" />
          <RoleBadge role="support" />
          <RoleBadge role="client" you />
        </Row>
      </Spec>
      <Spec state={l('Participant strip · the header of the group chat (opens the member sheet)', 'شريط المشاركين · رأس المحادثة الجماعية (يفتح ورقة الأعضاء)')}>
        <ParticipantStrip members={t.thread.members as ThreadMember[]} meId="user-reem" onOpen={() => undefined} />
      </Spec>
      <Spec state={l('Member sheet form · with the organisation under the representative', 'شكل ورقة الأعضاء · مع اسم الجهة تحت الممثل')}>
        <ParticipantStrip members={t.thread.members as ThreadMember[]} meId="user-reem" showOrganisation />
      </Spec>
    </Section>
  )
}

export function GroupChatSection() {
  const l = useL()
  const { lang } = useLang()
  const client = useThread('visit-aurelia-reem', 'client')
  const hotel = useThread('visit-aurelia-reem', 'hotel')
  const members = client.thread.members as ThreadMember[]
  const roleOf = (m: Message): ThreadMember['role'] | null => (m.from === 'client' ? 'client' : m.from === 'venue' ? 'hotel_representative' : m.from === 'support' ? 'support' : null)
  const nameOf = (role: ThreadMember['role']) => {
    const m = members.find(x => x.role === role)
    return m ? (lang === 'ar' ? m.name : m.nameLatin) : ''
  }
  const run = (msgs: Message[], side: 'client' | 'hotel') =>
    msgs.map((m, i) => {
      const role = roleOf(m)
      const prev = msgs[i - 1]
      const first = !prev || prev.from !== m.from
      const own = side === 'client' ? m.from === 'client' : m.from === 'venue'
      return (
        <ChatBubble
          key={m.id}
          message={m}
          side={side}
          group={m.kind === 'system' ? 'info' : undefined}
          sender={role && first ? { name: nameOf(role), role, you: own } : undefined}
          showMeta={!msgs[i + 1] || msgs[i + 1]?.from !== m.from}
        />
      )
    })
  return (
    <Section
      id="group-chat"
      title={l('Group chat', 'المحادثة الجماعية')}
      note={l(
        'The shared ChatBubble with two additions for the three-way chat: a sender line above the first bubble of a run (name, then the role badge) and a quiet glyph on system lines (opened, confirmed, arrived, read-only). Own messages sit at inline-end in ink; a visit card shows the appointment.',
        'ChatBubble المشترك مع إضافتين للمحادثة الثلاثية: سطر المرسل فوق أول فقاعة في كل سلسلة (الاسم ثم شارة الدور) ورمز هادئ على أسطر النظام (فتح المحادثة والتأكيد والوصول وللقراءة فقط). رسائل المستخدم عند نهاية السطر بالحبر؛ وبطاقة الزيارة تعرض الموعد.',
      )}
    >
      <Spec state={l('The client’s phone', 'هاتف العميل')}>
        <ChatDateDivider date={client.messages[0]?.at ?? ''} />
        <div className="gc-chat">{run(client.messages.slice(0, 6), 'client')}</div>
      </Spec>
      <Spec state={l('The hotel representative’s phone (same chat, own messages flip sides)', 'هاتف ممثل الفندق (المحادثة نفسها وتنقلب رسائله)')}>
        <div className="gc-chat">{run(hotel.messages.slice(0, 6), 'hotel')}</div>
      </Spec>
    </Section>
  )
}

export function VisitCardSection() {
  const l = useL()
  const [confirmed, completed, requested] = ['visit-aurelia-reem', 'visit-lumi-reem', 'visit-aurelia-rashed'].map(id => {
    const v = visits.find(x => x.id === id)
    if (!v) throw new Error(id)
    return v
  }) as [(typeof visits)[number], (typeof visits)[number], (typeof visits)[number]]
  return (
    <Section
      id="visit-card"
      title={l('Visit card', 'بطاقة الزيارة')}
      note={l(
        'One site visit: status pill, the date and the 30-minute arrival window in the figures voice, who it is with, the party size and one action into the group chat. The client sees the venue; the partner sees the client. A visit is free and independent of the voucher.',
        'زيارة واحدة للقاعة: شارة الحالة والتاريخ ونافذة الوصول (30 دقيقة) بصوت الأرقام، ومع من هي وعدد الزائرين وإجراء واحد إلى المحادثة الجماعية. يرى العميل المكان ويرى الشريك العميل. الزيارة مجانية ومستقلة عن الكوبون.',
      )}
    >
      <Spec state={l('Client · confirmed · open the group chat', 'العميل · مؤكدة · فتح المحادثة الجماعية')}>
        <VisitCard visit={confirmed} onOpenChat={() => undefined} onOpen={() => undefined} />
      </Spec>
      <Spec state={l('Client · completed (chat read-only)', 'العميل · مكتملة (المحادثة للقراءة فقط)')}>
        <VisitCard visit={completed} onOpenChat={() => undefined} />
      </Spec>
      <Spec state={l('Partner · requested', 'الشريك · طلب زيارة')}>
        <VisitCard visit={requested} audience="hotel" onOpenChat={() => undefined} onOpen={() => undefined} />
      </Spec>
    </Section>
  )
}
