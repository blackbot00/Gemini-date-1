import os
import logging
import requests
from dotenv import load_dotenv
from pymongo import MongoClient
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import (
    ApplicationBuilder, CommandHandler, ContextTypes, 
    CallbackQueryHandler, MessageHandler, filters, ConversationHandler
)

# Load environment variables
load_dotenv()

# Logging setup
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)

# Database Setup
client = MongoClient(os.getenv("MONGO_URI"))
db = client['dating_bot_db']
users_col = db['users']

# Conversation States
START_REG, GET_GENDER, GET_AGE, GET_STATE, MAIN_MENU, CHATTING_HUMAN, CHATTING_AI = range(7)

# Matchmaking Queue
waiting_users = []
active_chats = {}

# --- AI Function ---
def get_ai_response(user_message, user_gender):
    role = "sweet girlfriend" if user_gender == "Male" else "caring boyfriend"
    headers = {
        "Authorization": f"Bearer {os.getenv('OPENROUTER_API_KEY')}",
        "Content-Type": "application/json"
    }
    data = {
        "model": "google/gemini-2.0-flash-exp:free",
        "messages": [
            {"role": "system", "content": f"You are a {role} in a dating app. Talk in Tanglish. Use heart emojis. Be romantic."},
            {"role": "user", "content": user_message}
        ]
    }
    try:
        response = requests.post("https://openrouter.ai/api/v1/chat/completions", headers=headers, json=data)
        return response.json()['choices'][0]['message']['content']
    except:
        return "Sorry dear, chinna network issue. Konjam kazhithu pesalaama? 🥺"

# --- Handlers ---
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    keyboard = [[InlineKeyboardButton("🚀 Start Registration ✨", callback_data="reg_start")]]
    await update.message.reply_text(
        "👋 **Welcome to SoulConnect!** \n\nFind your perfect match today! ❤️",
        reply_markup=InlineKeyboardMarkup(keyboard), parse_mode='Markdown'
    )
    return START_REG

async def gender_step(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    keyboard = [[InlineKeyboardButton("👨 Male", callback_data="Male"), InlineKeyboardButton("👩 Female", callback_data="Female")]]
    await query.edit_message_text("🌈 Select your **Gender**:", reply_markup=InlineKeyboardMarkup(keyboard), parse_mode='Markdown')
    return GET_GENDER

async def age_step(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    context.user_data['gender'] = query.data
    await query.answer()
    await query.edit_message_text("🎂 Great! Now type your **Age** (e.g. 22) ✍️")
    return GET_AGE

async def state_step(update: Update, context: ContextTypes.DEFAULT_TYPE):
    context.user_data['age'] = update.message.text
    keyboard = [[InlineKeyboardButton("Tamil Nadu", callback_data="Tamil Nadu"), InlineKeyboardButton("Kerala", callback_data="Kerala")]]
    await update.message.reply_text("📍 Which **State** are you from?", reply_markup=InlineKeyboardMarkup(keyboard))
    return GET_STATE

async def save_and_menu(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    user_id = update.effective_user.id
    context.user_data['state'] = query.data
    
    # Save to MongoDB
    users_col.update_one(
        {"user_id": user_id}, 
        {"$set": {"user_id": user_id, "gender": context.user_data['gender'], "age": context.user_data['age'], "state": context.user_data['state']}}, 
        upsert=True
    )
    
    keyboard = [
        [InlineKeyboardButton("👤 Chat with Human 💬", callback_data="human_chat")],
        [InlineKeyboardButton("🤖 Chat with AI (GF/BF) 🧸", callback_data="ai_chat")]
    ]
    await query.edit_message_text("✅ **Registration Completed!** 🎊\nChoose your mood:", reply_markup=InlineKeyboardMarkup(keyboard))
    return MAIN_MENU

# --- Logic for Human Chat ---
async def start_human_chat(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    user_id = update.effective_user.id
    await query.answer()

    if waiting_users and waiting_users[0] != user_id:
        partner_id = waiting_users.pop(0)
        active_chats[user_id] = partner_id
        active_chats[partner_id] = user_id
        await query.edit_message_text("🔥 **Match Found!** Start talking... \nType /exit to leave. 🛑")
        await context.bot.send_message(partner_id, "🔥 **Match Found!** Connect aagiyaachu. Pesunga! 💬")
        return CHATTING_HUMAN
    else:
        if user_id not in waiting_users: waiting_users.append(user_id)
        await query.edit_message_text("⏳ Searching for someone special... Please wait. ✨")
        return MAIN_MENU

# --- Logic for AI Chat ---
async def start_ai_chat(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    await query.edit_message_text("🤖 AI mode activated! Pesalam vaanga... ❤️\n(Type /exit to go back)")
    return CHATTING_AI

async def ai_message_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    user_text = update.message.text
    user_profile = users_col.find_one({"user_id": user_id})
    
    reply = get_ai_response(user_text, user_profile.get('gender', 'Male'))
    await update.message.reply_text(reply)

async def human_message_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    if user_id in active_chats:
        await context.bot.send_message(active_chats[user_id], f"💬: {update.message.text}")

async def stop(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    if user_id in active_chats:
        partner_id = active_chats.pop(user_id)
        active_chats.pop(partner_id, None)
        await context.bot.send_message(partner_id, "❌ Partner disconnected. /start to find new.")
    
    if user_id in waiting_users: waiting_users.remove(user_id)
    await update.message.reply_text("🛑 Chat ended. /start to menu.")
    return ConversationHandler.END

if __name__ == '__main__':
    app = ApplicationBuilder().token(os.getenv("TELEGRAM_TOKEN")).build()
    
    conv = ConversationHandler(
        entry_points=[CommandHandler('start', start)],
        states={
            START_REG: [CallbackQueryHandler(gender_step, pattern="^reg_start$")],
            GET_GENDER: [CallbackQueryHandler(age_step)],
            GET_AGE: [MessageHandler(filters.TEXT & ~filters.COMMAND, state_step)],
            GET_STATE: [CallbackQueryHandler(save_and_menu)],
            MAIN_MENU: [
                CallbackQueryHandler(start_human_chat, pattern="^human_chat$"),
                CallbackQueryHandler(start_ai_chat, pattern="^ai_chat$")
            ],
            CHATTING_HUMAN: [MessageHandler(filters.TEXT & ~filters.COMMAND, human_message_handler)],
            CHATTING_AI: [MessageHandler(filters.TEXT & ~filters.COMMAND, ai_message_handler)],
        },
        fallbacks=[CommandHandler('exit', stop)]
    )
    
    app.add_handler(conv)
    print("Bot is alive... ✨")
    app.run_polling()
    
