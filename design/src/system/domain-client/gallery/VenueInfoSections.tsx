// Gallery: reviews, ratings, amenities, policies, FAQ and the map preview, from the Aurelia fixture (and the stress venue with no reviews).
import { requireVenue, reviewsFor, stress } from '../../../mock'
import { AmenityGrid, FaqAccordion, MapPreview, PolicyList } from '../VenueInfo'
import { RatingSummary, ReviewCard } from '../ReviewCard'
import { useBi } from '../bits'
import { Section, Spec, useL } from './kit'

export function ReviewSection() {
  const l = useL()
  const bi = useBi()
  const v = requireVenue('V01')
  const reviews = reviewsFor('V01')
  const replied = reviews.find(r => r.ownerReply)!
  const plain = reviews.find(r => !r.ownerReply && r.rating >= 4.8)!
  const critical = reviews.find(r => r.rating < 4)!
  const shots = v.gallery.filter(g => g.zone === 'buffet' || g.zone === 'stage_kosha').slice(0, 3).map(g => g.file)
  const none = stress.venues.find(x => x.rating.count === 0)
  return (
    <Section
      id="reviews"
      title={l('Reviews and rating', 'التقييمات')}
      note={l(
        'Ruled blocks, not cards. A monogram, never a face; the text as typed, in its own language; empty-room photographs only; the owner’s reply set apart. The summary uses figures, not the serif, and a venue with no reviews says "New", never 0.0.',
        'كتل مفصولة بخطوط لا بطاقات. حرف أول لا وجه؛ والنص كما كُتب بلغته؛ وصور لقاعات فارغة فقط؛ وردّ المكان منفصل. الملخص بأرقام لا بالخط ذي الزوائد، والقاعة بلا تقييمات تقول «جديد» لا 0.0.',
      )}
    >
      <Spec state={l('Rating summary · average, stars, count, four category bars', 'ملخص التقييم · المتوسط والنجوم والعدد وأربعة أشرطة')}>
        <RatingSummary venue={v} />
      </Spec>
      <Spec state={l('No reviews yet (stress S03)', 'بلا تقييمات بعد (حالة ضغط S03)')}>{none ? <RatingSummary venue={none} /> : null}</Spec>
      <Spec state={l('Review with the owner’s reply', 'تقييم مع ردّ المكان')}>
        <ReviewCard review={replied} venueName={bi(v.name)} />
      </Spec>
      <Spec state={l('With photographs · verified booking · long text collapses', 'مع صور · حجز موثّق · النص الطويل يُطوى')}>
        <ReviewCard review={{ ...plain, text: { en: `${plain.text.en} ${plain.text.en}`, ar: `${plain.text.ar} ${plain.text.ar} ${plain.text.ar}` } }} photos={shots} />
      </Spec>
      <Spec state={l('A critical review · anonymous guest', 'تقييم نقدي · ضيف مجهول')}>
        <ReviewCard review={{ ...critical, anonymous: true }} />
      </Spec>
    </Section>
  )
}

export function VenueInfoSection() {
  const l = useL()
  const bi = useBi()
  const v = requireVenue('V01')
  const facts = v.halls[0]!.sections[0]!.policy
  return (
    <Section
      id="venue-info"
      title={l('Facilities, rules, questions and location', 'المرافق والقواعد والأسئلة والموقع')}
      note={l(
        'Facilities in three states with icon and words, rules as plain labelled facts, the venue’s own questions in the accordion, and a static map drawn from tokens: no tiles, no blur, one pin.',
        'المرافق بثلاث حالات بأيقونة ونص، والقواعد كحقائق واضحة بعناوين، وأسئلة المكان في الأكورديون، وخريطة ثابتة مرسومة من الرموز: بلا بلاطات ولا ضبابية ودبوس واحد.',
      )}
    >
      <Spec state={l('Amenity grid · included, extra with a price anchor, not offered', 'شبكة المرافق · مشمول وإضافة بسعر تقريبي وغير متوفر')}>
        <AmenityGrid amenities={v.amenities} collapsedCount={10} />
      </Spec>
      <Spec state={l('Policy list · plain facts, never a judgement', 'قائمة القواعد · حقائق واضحة دون أحكام')}>
        <PolicyList
          facts={facts}
          extra={[
            { label: l('Children', 'الأطفال'), value: bi(v.policies.children.women) },
            { label: l('Dress code', 'اللباس'), value: bi(v.policies.dressCode) },
          ]}
        />
      </Spec>
      <Spec state={l('FAQ accordion · single open', 'أسئلة شائعة · سؤال واحد مفتوح')}>
        <FaqAccordion items={v.faq} defaultOpenId={v.faq[0]?.id} />
      </Spec>
      <Spec state={l('Map preview · static illustration, a pin, the drive time', 'معاينة الخريطة · رسم ثابت ودبوس ووقت القيادة')}>
        <MapPreview venue={v} origin={{ id: 'ref-salmiya', name: l('Salmiya', 'السالمية') }} onOpen={() => undefined} />
        <MapPreview venue={requireVenue('V03')} origin={{ id: 'ref-salmiya', name: l('Salmiya', 'السالمية') }} />
      </Spec>
    </Section>
  )
}
