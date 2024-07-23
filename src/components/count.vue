<template>
    <div class="count-page">
        <div>{{ count }}</div>
        <button @click="handleAdd">Add</button>
    </div>
</template>

<script setup>
import { ref } from 'vue';
const count = ref(0)
const handleAdd = () => {
    count++;
}
</script>

<style scoped lang="scss">
.count-page {
    padding: 40px;
}
</style>