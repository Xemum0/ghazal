// Thumb: the venue's cover photograph at 56, or the provider's monogram (never a face). One square for every voucher row and plate.
import { Avatar, Photo, imageSrc } from '../../../../system'
import { useLang } from '../../../../shell/lang'
import type { Facts } from './model'
import './thumb.css'

export function Thumb({ facts }: { facts: Facts }) {
  const { lang } = useLang()
  if (facts.cover) return <Photo className="gzv-thumb" src={imageSrc(facts.cover.file)} alt={facts.cover.alt[lang]} sizes="56px" />
  return <Avatar name={facts.name} initial={facts.monogram || undefined} size="md" />
}
