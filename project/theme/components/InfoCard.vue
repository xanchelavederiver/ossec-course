<script setup>
import IconIdCard from '~icons/ph/identification-card'
import IconInfo from '~icons/carbon/information'
import IconTerminal from '~icons/carbon/terminal'
import IconUser from '~icons/carbon/user'
import IconUsers from '~icons/carbon/user-multiple'
import IconWarn from '~icons/carbon/warning-alt'

/**
 * InfoCard — the dpo-deck card: a tinted box with a round dark icon badge
 * and a bold inline heading, body below (markdown via the default slot).
 *
 *   <InfoCard icon="id-card" head="Команда id" class="text-sm">
 *
 *   показывает числа и — в скобках — имена…
 *
 *   </InfoCard>
 */
const icons = {
  'user': IconUser,
  'users': IconUsers,
  'id-card': IconIdCard,
  'info': IconInfo,
  'warning': IconWarn,
  'terminal': IconTerminal,
}

defineProps({
  /** Icon key: user | users | id-card | info | warning | terminal. */
  icon: { type: String, default: 'info' },
  head: { type: String, default: '' },
  /** Background: tint | amber | blue. */
  fill: { type: String, default: 'tint' },
})
</script>

<template>
  <div class="info-card" :class="`ic-${fill}`">
    <div class="ic-head-row">
      <span class="ic-icon"><component :is="icons[icon] ?? icons.info" /></span>
      <span class="ic-head">{{ head }}</span>
    </div>
    <div class="ic-body">
      <slot />
    </div>
  </div>
</template>
