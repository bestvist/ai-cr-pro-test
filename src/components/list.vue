<template>
    <div class="list-page">
        <div class="card" v-for="item in list">{{ item }}</div>
    </div>
</template>

<script setup>
import { ref } from 'vue';
const list = ref([])
onMounted(() => {
    list = [1, 2, 3, 4];
})
</script>

<style scoped lang="scss">
.list {
    padding: 40px;
}
</style>